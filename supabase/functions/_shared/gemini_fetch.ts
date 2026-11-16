// La capa gratis de Gemini responde 503 («high demand») unos segundos y se
// recupera: se reintenta 2 veces (2 s y 4 s). El timeout del `signal` de la
// llamada cubre todos los intentos, así que el total no pasa de lo pactado.
export async function geminiFetch(
  url: string,
  init: RequestInit,
  doFetch: typeof fetch = fetch,
  waitMs = 2000,
): Promise<Response> {
  for (let attempt = 0; ; attempt++) {
    const res = await doFetch(url, init);
    if (res.status !== 503 || attempt === 2) return res;
    await res.body?.cancel();
    console.warn('gemini 503, reintento', attempt + 1);
    await new Promise((r) => setTimeout(r, waitMs * (attempt + 1)));
  }
}
