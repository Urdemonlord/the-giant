// VHS analog-horror overlay THE GIANT (dipakai HUD game + menu utama).
// Satu file supaya kedua layar tidak bisa drift: angka intensitas
// tinggal di Balance, shader ini cuma bentuknya. Dulu inline string
// di hud.gd (v5-v15); dipindah ke file di v17 saat menu butuh shader
// yang sama untuk latar 3D-nya. Isi TIDAK berubah.
// (Komentar shader pakai //, bukan ## — ## itu komentar GDScript dan
// bikin file shader ini gagal compile diam-diam: fx jadi putih polos.)
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture;
uniform float grain : hint_range(0.0, 1.0) = 0.13;
uniform float scanline : hint_range(0.0, 1.0) = 0.10;
uniform float ca : hint_range(0.0, 0.01) = 0.0016;
uniform float desat : hint_range(0.0, 1.0) = 0.45;
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float flicker : hint_range(0.0, 0.2) = 0.04;
uniform float tear_shift : hint_range(0.0, 0.1) = 0.02;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	// Tracking tear: di ~70% jendela 4 detik, sebuah pita horizontal
	// bergeser selama 0.16 detik, lalu kembali normal.
	float cycle = floor(TIME / 4.0);
	float phase = fract(TIME / 4.0);
	float tear_on = step(hash(vec2(cycle, 7.0)), 0.7) * step(phase, 0.04);
	float band_y = hash(vec2(cycle, 13.0));
	float band = step(abs(uv.y - band_y), 0.03) * tear_on;
	uv.x += band * tear_shift * (hash(vec2(cycle, 3.0)) - 0.5) * 2.0;
	// Chromatic aberration, makin kuat ke tepi layar.
	float edge = length(uv - 0.5) * 2.0;
	vec2 off = vec2(ca * (0.5 + edge), 0.0);
	vec3 col;
	col.r = texture(screen_texture, uv + off).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - off).b;
	// Desaturasi ke abu netral (v32: dulu hijau-abu sakit (0.92, 1.0,
	// 0.88) — itu sumber hijau KEDUA di screenshot, selain warna
	// kabut; dinetralkan bareng kabut atas pilihan Arya 20:05 WIB).
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 sick = vec3(lum) * vec3(0.99, 1.0, 1.01);
	col = mix(col, sick, desat);
	// Scanlines.
	col *= 1.0 - scanline * (0.5 + 0.5 * sin(uv.y * 2262.0));
	// Rolling band (v14): pita terang redup yang merayap pelan ke
	// bawah, khas VHS. Amplitudo 0.03 saja: terasa, tidak mengganggu.
	col *= 1.0 + 0.03 * sin((uv.y + TIME * 0.05) * 6.2831);
	// Grain VHS bergerak.
	float n = hash(uv * vec2(1280.0, 720.0) + vec2(TIME * 60.0, -TIME * 47.0));
	col += (n - 0.5) * grain;
	// Vignette.
	float d = length(uv - 0.5) * 2.0;
	col *= 1.0 - vignette * smoothstep(0.6, 1.4, d);
	// Flicker: napas halus + sesekali redup mendadak.
	float dip = step(0.94, hash(vec2(floor(TIME * 3.0), 5.0))) * 0.08;
	col *= 1.0 - dip + flicker * sin(TIME * 13.0) * 0.5;
	COLOR = vec4(col, 1.0);
}
