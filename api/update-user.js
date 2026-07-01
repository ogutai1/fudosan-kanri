export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { email, name, role, password } = req.body;
  if (!email) return res.status(400).json({ error: 'email required' });

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
  if (!SUPABASE_URL || !SERVICE_KEY) return res.status(500).json({ error: 'Server config missing' });

  const h = {
    'Authorization': 'Bearer ' + SERVICE_KEY,
    'apikey': SERVICE_KEY,
    'Content-Type': 'application/json'
  };

  // Find user by email
  const listRes = await fetch(SUPABASE_URL + '/auth/v1/admin/users?per_page=50', { headers: h });
  const listData = await listRes.json();
  const user = listData.users?.find(u => u.email === email);
  if (!user) return res.status(404).json({ error: 'User not found' });

  // Build update payload
  const body = {};
  if (name || role) {
    body.user_metadata = { ...user.user_metadata, ...(name ? { name } : {}), ...(role ? { role } : {}) };
  }
  if (password) body.password = password;

  const updateRes = await fetch(SUPABASE_URL + '/auth/v1/admin/users/' + user.id, {
    method: 'PUT', headers: h, body: JSON.stringify(body)
  });
  const updated = await updateRes.json();
  if (updated.error) return res.status(400).json({ error: updated.error });
  return res.status(200).json({ ok: true, email: updated.email });
}
