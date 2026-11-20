shader_type canvas_item;
render_mode unshaded;

// Both ratios are width/height (pixel sizes are reciprocals).
// The full-screen TextureRect supplies UV in [0,1].
void fragment() {
    float view_aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    float image_aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    vec2 cover = vec2(min(1.0, view_aspect / image_aspect),
                      min(1.0, image_aspect / view_aspect));
    float framing = view_aspect < 0.9 ? 1.35 : 1.0;
    vec2 source_uv = vec2(0.5) + (UV-vec2(0.5))*cover*framing;
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec2 safe_uv = clamp(source_uv,px,vec2(1.0)-px);
    // Screen-space detail enhancement, limited to reduce overshoot.
    vec2 dx = vec2(max(abs(dFdx(source_uv.x)),px.x)*0.85,0.0);
    vec2 dy = vec2(0.0,max(abs(dFdy(source_uv.y)),px.y)*0.85);
    vec3 c = texture(TEXTURE,safe_uv).rgb;
    vec3 l = texture(TEXTURE,clamp(safe_uv-dx,px,vec2(1.0)-px)).rgb;
    vec3 r = texture(TEXTURE,clamp(safe_uv+dx,px,vec2(1.0)-px)).rgb;
    vec3 t = texture(TEXTURE,clamp(safe_uv-dy,px,vec2(1.0)-px)).rgb;
    vec3 b = texture(TEXTURE,clamp(safe_uv+dy,px,vec2(1.0)-px)).rgb;
    vec3 avg = (l+r+t+b)*0.25;
    vec3 lo = min(c,min(min(l,r),min(t,b)));
    vec3 hi = max(c,max(max(l,r),max(t,b)));
    vec3 clear = clamp(c+(c-avg)*0.42,lo-vec3(0.015),hi+vec3(0.015));
    float edge = min(min(source_uv.x,1.0-source_uv.x),min(source_uv.y,1.0-source_uv.y));
    float art = framing>1.0 ? smoothstep(0.0,0.055,edge) : 1.0;
    vec3 surround = mix(vec3(0.055,0.075,0.14),c,0.12);
    COLOR = vec4(clamp(mix(surround,clear,art),0.0,1.0),1.0);
}
