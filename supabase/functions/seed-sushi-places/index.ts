import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type SeedRequest = {
  latitude?: number;
  longitude?: number;
  radiusMeters?: number;
  query?: string;
  maxResultCount?: number;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const googleApiKey = Deno.env.get("GOOGLE_PLACES_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!googleApiKey || !supabaseUrl || !serviceRoleKey) {
    return json({ error: "Seed function is not configured" }, 500);
  }

  const userId = await authenticatedUserId(req);
  if (!userId) return json({ error: "Unauthorized" }, 401);
  if (!isAllowedAdmin(userId)) return json({ error: "Forbidden" }, 403);

  const body = await req.json().catch(() => ({})) as SeedRequest;
  const latitude = numberOrDefault(body.latitude, 43.6532);
  const longitude = numberOrDefault(body.longitude, -79.3832);
  const radiusMeters = clamp(numberOrDefault(body.radiusMeters, 5000), 100, 50000);
  const maxResultCount = clamp(
    Math.floor(numberOrDefault(body.maxResultCount, 20)),
    1,
    20,
  );
  const textQuery = cleanText(body.query) ?? "sushi restaurants";

  const places = await searchGooglePlaces({
    apiKey: googleApiKey,
    latitude,
    longitude,
    radiusMeters,
    maxResultCount,
    textQuery,
  });

  const rows = places
    .map((place) => toLocationRow(place, userId))
    .filter((row) => row.google_place_id !== null);
  if (rows.length === 0) {
    return json({ inserted: 0, updated: 0, locations: [] });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await supabase
    .from("locations")
    .upsert(rows, { onConflict: "google_place_id" })
    .select("id, name, google_place_id, formatted_address, latitude, longitude");

  if (error) {
    return json({ error: error.message }, 500);
  }

  return json({
    count: data?.length ?? 0,
    locations: data ?? [],
  });
});

async function searchGooglePlaces({
  apiKey,
  latitude,
  longitude,
  radiusMeters,
  maxResultCount,
  textQuery,
}: {
  apiKey: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  maxResultCount: number;
  textQuery: string;
}) {
  const response = await fetch(
    "https://places.googleapis.com/v1/places:searchText",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": [
          "places.id",
          "places.displayName",
          "places.formattedAddress",
          "places.location",
          "places.rating",
          "places.userRatingCount",
          "places.priceLevel",
          "places.businessStatus",
          "places.googleMapsUri",
          "places.primaryType",
          "places.types",
          "places.nationalPhoneNumber",
          "places.websiteUri",
          "places.regularOpeningHours",
        ].join(","),
      },
      body: JSON.stringify({
        textQuery,
        maxResultCount,
        locationBias: {
          circle: {
            center: { latitude, longitude },
            radius: radiusMeters,
          },
        },
        includedType: "restaurant",
      }),
    },
  );

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      `Google Places failed with ${response.status}: ${JSON.stringify(payload)}`,
    );
  }
  return Array.isArray(payload.places) ? payload.places : [];
}

function toLocationRow(place: Record<string, unknown>, userId: string) {
  const displayName = place.displayName as { text?: string } | undefined;
  const location = place.location as
    | { latitude?: number; longitude?: number }
    | undefined;
  const regularOpeningHours = place.regularOpeningHours ?? null;
  const formattedAddress = stringOrNull(place.formattedAddress);

  return {
    google_place_id: stringOrNull(place.id),
    name: displayName?.text ?? "Unnamed sushi place",
    address: formattedAddress,
    formatted_address: formattedAddress,
    latitude: location?.latitude ?? null,
    longitude: location?.longitude ?? null,
    phone: stringOrNull(place.nationalPhoneNumber),
    website: stringOrNull(place.websiteUri),
    rating: numberOrNull(place.rating),
    user_rating_count: integerOrNull(place.userRatingCount),
    price_level: stringOrNull(place.priceLevel),
    business_status: stringOrNull(place.businessStatus),
    google_maps_uri: stringOrNull(place.googleMapsUri),
    primary_type: stringOrNull(place.primaryType),
    types: Array.isArray(place.types)
      ? place.types.filter((type) => typeof type === "string")
      : [],
    opening_hours: regularOpeningHours,
    google_data: place,
    last_google_sync_at: new Date().toISOString(),
    created_by: userId,
  };
}

async function authenticatedUserId(req: Request) {
  const authHeader = req.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authHeader || !supabaseUrl || !anonKey) return null;

  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization: authHeader, apikey: anonKey },
  });
  if (!res.ok) return null;
  const user = await res.json();
  return typeof user.id === "string" ? user.id : null;
}

function isAllowedAdmin(userId: string) {
  const adminIds = Deno.env.get("ADMIN_USER_IDS");
  if (!adminIds?.trim()) return true;
  return adminIds.split(",").map((id) => id.trim()).includes(userId);
}

function cleanText(value: unknown) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function numberOrDefault(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function integerOrNull(value: unknown) {
  return typeof value === "number" && Number.isInteger(value) ? value : null;
}

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
