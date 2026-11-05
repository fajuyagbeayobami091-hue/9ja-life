import { createClient } from 'npm:@supabase/supabase-js@2';

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST required" }), { status: 405, headers: cors });
  }

  try {
    const body = await req.json();
    const name = String(body.name || "").trim();
    const phone = String(body.phone || "").trim();
    const address = String(body.address || "").trim();
    const paymentMethod = String(body.payment_method || "");

    if (name.length < 2 || phone.length < 7 || address.length < 8) {
      throw new Error("Enter your name, phone number, and full delivery address.");
    }
    if (!["bank_transfer", "cash_on_delivery"].includes(paymentMethod)) {
      throw new Error("Choose a payment method.");
    }
    if (!Array.isArray(body.items) || !body.items.length || body.items.length > 30) {
      throw new Error("Your basket is empty or too large.");
    }

    const secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
      JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}").default;
    if (!secret) throw new Error("Server is not configured with its database secret.");

    const db = createClient(Deno.env.get("SUPABASE_URL")!, secret);
    const slugs = [...new Set(body.items.map((item: any) => String(item.slug || "")))];
    const { data: menuRows, error: menuError } = await db
      .from("menu_items")
      .select("slug,name,price_ngn")
      .in("slug", slugs)
      .eq("active", true);
    if (menuError) throw menuError;

    const menu = new Map<string, any>((menuRows || []).map((item: any) => [item.slug, item] as [string, any]));
    const items = body.items.map((item: any) => {
      const product = menu.get(String(item.slug || ""));
      const quantity = Number(item.quantity);
      if (!product || !Number.isInteger(quantity) || quantity < 1 || quantity > 50) {
        throw new Error("A menu item is unavailable or has an invalid quantity.");
      }
      return {
        slug: product.slug,
        name: product.name,
        quantity,
        unit_price_ngn: product.price_ngn,
      };
    });

    const total = items.reduce((sum: number, item: any) => sum + item.quantity * item.unit_price_ngn, 0);
    const trackingCode = "NJ-" + crypto.randomUUID().replaceAll("-", "").slice(0, 10).toUpperCase();
    const { data, error } = await db.from("orders").insert({
      tracking_code: trackingCode,
      customer_name: name,
      phone,
      delivery_address: address,
      items,
      total_ngn: total,
      payment_method: paymentMethod,
      payment_status: paymentMethod === "bank_transfer" ? "pending_confirmation" : "unpaid",
    }).select("tracking_code,status,total_ngn,payment_method,payment_status").single();

    if (error) throw error;
    return new Response(JSON.stringify({ order: data }), { headers: cors });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Could not create order" }), {
      status: 400,
      headers: cors,
    });
  }
});
