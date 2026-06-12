# Seed Sushi Places

Set your Google Places API key:

```bash
supabase secrets set GOOGLE_PLACES_API_KEY="YOUR_GOOGLE_PLACES_API_KEY"
```

Run the seed function:

```bash
curl -X POST "https://xattcymvfutogrxszgen.supabase.co/functions/v1/seed-sushi-places" \
  -H "Authorization: Bearer YOUR_USER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 44.0592,
    "longitude": -79.4613,
    "radiusMeters": 10000,
    "query": "all you can eat sushi",
    "maxResultCount": 20
  }'
```

Replace `YOUR_USER_ACCESS_TOKEN` with a logged-in Supabase user's access token.
