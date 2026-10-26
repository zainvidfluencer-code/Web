import { withSupabase } from 'npm:@supabase/server@1'

const buckets = ['creator-contracts', 'creator-portfolios', 'creator-avatars']
const recentAuthSeconds = 10 * 60

async function listCreatorObjects(admin: any, bucket: string, prefix: string): Promise<string[]> {
  const paths: string[] = []
  let offset = 0
  const pageSize = 100

  while (true) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: pageSize, offset })
    if (error) throw new Error(`Could not inspect ${bucket}: ${error.message}`)
    const entries = data || []
    for (const entry of entries) {
      const path = `${prefix}/${entry.name}`
      if (entry.id === null) paths.push(...await listCreatorObjects(admin, bucket, path))
      else paths.push(path)
    }
    if (entries.length < pageSize) break
    offset += entries.length
  }
  return paths
}

async function removeCreatorObjects(admin: any, bucket: string, userId: string) {
  const paths = await listCreatorObjects(admin, bucket, userId)
  for (let index = 0; index < paths.length; index += 100) {
    const { error } = await admin.storage.from(bucket).remove(paths.slice(index, index + 100))
    if (error) throw new Error(`Could not remove ${bucket} files: ${error.message}`)
  }
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (request, ctx) => {
    if (request.method !== 'POST') return Response.json({ error: 'Use POST for account deletion.' }, { status: 405 })

    const userId = ctx.jwtClaims?.sub
    const authTime = Number(ctx.jwtClaims?.auth_time)
    const now = Math.floor(Date.now() / 1000)
    if (typeof userId !== 'string' || !userId) return Response.json({ error: 'Sign in again before deleting this account.' }, { status: 401 })
    if (!Number.isFinite(authTime) || authTime > now || now - authTime > recentAuthSeconds) {
      return Response.json({ error: 'For your security, sign in again before deleting this account.' }, { status: 401 })
    }

    const { data: isAdmin, error: roleError } = await ctx.supabase.rpc('is_admin')
    if (roleError) return Response.json({ error: 'Could not verify the account role. Try again.' }, { status: 500 })
    if (isAdmin) return Response.json({ error: 'Admin accounts cannot use creator account deletion.' }, { status: 403 })

    try {
      // Remove private files before deleting the Auth user; Supabase Storage requires
      // an account's owned objects to be removed first.
      for (const bucket of buckets) await removeCreatorObjects(ctx.supabaseAdmin, bucket, userId)

      // Keep the financial ledger for admin records, but remove the account link and
      // personal snapshots before auth.users cascades the creator profile/apps.
      const { error: anonymizeError } = await ctx.supabaseAdmin
        .from('creator_earnings')
        .update({ creator_id: null, creator_name_snapshot: null, creator_email_snapshot: null, updated_at: new Date().toISOString() })
        .eq('creator_id', userId)
      if (anonymizeError) throw new Error(`Could not preserve the payment record safely: ${anonymizeError.message}`)

      const { error: deleteError } = await ctx.supabaseAdmin.auth.admin.deleteUser(userId)
      if (deleteError) throw new Error(`Could not delete the account: ${deleteError.message}`)
      return Response.json({ success: true })
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Account deletion could not be completed.'
      return Response.json({ error: message }, { status: 500 })
    }
  }),
}
