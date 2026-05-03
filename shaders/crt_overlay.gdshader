shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.04;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float crt_curvature : hint_range(0.0, 1.0) = 0.01;
uniform float flicker_intensity : hint_range(0.0, 0.05) = 0.005;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.18;
uniform float time_speed : hint_range(0.5, 5.0) = 1.0;

uniform vec4 glow_color : source_color = vec4(0.2, 1.0, 0.2, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (crt_curvature > 0.0) {
		vec2 centered = uv * 2.0 - 1.0;
		float dist2 = dot(centered, centered);
		centered *= 1.0 + crt_curvature * dist2;
		uv = centered * 0.5 + 0.5;
	}
	
	bool out_of_bounds = uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
	
	vec4 color = texture(screen_tex, uv);
	
	if (out_of_bounds) {
		color = vec4(0.0, 0.0, 0.0, 1.0);
	}
	
	float scanline = sin(uv.y * 600.0) * 0.5 + 0.5;
	scanline = pow(scanline, 1.2);
	color.rgb = mix(color.rgb, color.rgb * vec3(0.85, 0.93, 0.85), scanline_intensity * scanline);
	
	float flicker = sin(TIME * time_speed * 47.0) * flicker_intensity;
	color.rgb += flicker * color.rgb;
	
	color.rgb += glow_color.rgb * glow_intensity * (color.r + color.g + color.b) / 3.0 * 0.15;
	
	float cx = uv.x - 0.5;
	float cy = uv.y - 0.5;
	float vignette = 1.0 - dot(vec2(cx, cy), vec2(cx, cy)) * vignette_intensity * 3.0;
	vignette = clamp(vignette, 0.0, 1.0);
	color.rgb *= vignette;
	
	COLOR = vec4(color.rgb, 1.0);
}