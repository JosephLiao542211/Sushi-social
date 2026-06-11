# create-photo-upload

Returns a short-lived signed `PUT` URL for uploading feed photos to Google Cloud
Storage. Supabase stores the resulting object metadata in `public.posts`.

Required function secrets:

```bash
supabase secrets set GCS_PHOTOS_BUCKET="your-public-photo-bucket"
supabase secrets set GCS_CLIENT_EMAIL="service-account@project.iam.gserviceaccount.com"
supabase secrets set GCS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

The service account needs permission to create objects in the bucket. The app
stores `https://storage.googleapis.com/{bucket}/{object}` as `photo_url`, so the
bucket or uploaded objects must be readable by the app.

For Flutter web uploads, configure bucket CORS to allow browser `PUT` uploads:

```json
[
  {
    "origin": ["http://127.0.0.1:3000", "http://localhost:3000"],
    "method": ["PUT", "GET", "HEAD"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

Apply it with:

```bash
gcloud storage buckets update gs://your-public-photo-bucket --cors-file=cors.json
```
