shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float crt_curvature : hint_range(0.0, 0.1) = 0.03;
uniform float flicker_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float time_speed : hint_range(0.5, 5.0) = 1.0;

uniform vec4 glow_color : source_color = vec4(0.2, 1.0, 0.2, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float curvature = crt_curvature;
	if (curvature > 0.0) {
		uv = uv * 2.0 - 1.0;
		vec2 offset = abs(uv.yx) / vec2(2.0);
		uv = uv + uv * offset * offset;
		uv = uv * 0.5 + 0.5;
	}
	
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	
	vec4 color = texture(SCREEN_TEXTURE, uv);
	
	float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
	scanline = pow(scanline, 0.3);
	color.rgb = mix(color.rgb, color.rgb * vec3(0.7, 0.85, 0.7), scanline_intensity * scanline);
	
	float flicker = sin(TIME * time_speed * 60.0) * flicker_intensity;
	color.rgb += flicker * color.rgb;
	
	color.rgb += glow_color.rgb * glow_intensity * (color.r + color.g + color.b) / 3.0 * 0.3;
	
	float cx = uv.x - 0.5;
	float cy = uv.y - 0.5;
	float vignette = 1.0 - dot(vec2(cx, cy), vec2(cx, cy)) * vignette_intensity * 4.0;
	vignette = clamp(vignette, 0.0, 1.0);
	color.rgb *= vignette;
	
	COLOR = vec4(color.rgb, 1.0);
}