shader_type canvas_item;

// Author: Stefan Gustavson
// Title: Worley noise 2x2

uniform vec2 resolution;
uniform float time;

// Cellular noise ("Worley noise") in 2D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.

// Permutation polynomial: (34x^2 + x) mod 289
vec4 permute(vec4 x) 
{
  return mod((34.0 * x + 1.0) * x, 289.0);
}

const float K = 0.142857142857; // 1/7
const float K2 = 0.0714285714285; // K/2
uniform float mod1 = 0.8; // jitter 1.0 makes F1 wrong more often

// Cellular noise, returning F1 and F2 in a vec2.
// Speeded up by using 2x2 search window instead of 3x3,
// at the expense of some strong pattern artifacts.
// F2 is often wrong and has sharp discontinuities.
// If you need a smooth F2, use the slower 3x3 version.
// F1 is sometimes wrong, too, but OK for most purposes.
vec2 cellular2x2(vec2 P) {
	vec2 Pi = mod(floor(P), 289.0);
 	vec2 Pf = fract(P);
	vec4 Pfx = Pf.x + vec4(-0.5, -1.5, -0.5, -1.5);
	vec4 Pfy = Pf.y + vec4(-0.5, -0.5, -1.5, -1.5);
	vec4 p = permute(Pi.x + vec4(0.0, 1.0, 0.0, 1.0));
	p = permute(p + Pi.y + vec4(0.0, 0.0, 1.0, 1.0));
	vec4 ox = mod(p, 7.0)*K+K2;
	vec4 oy = mod(floor(p*K),7.0)*K+K2;
	vec4 dx = Pfx + mod1*ox;
	vec4 dy = Pfy + mod1*oy;
	vec4 d = dx * dx + dy * dy; // d11, d12, d21 and d22, squared
	// Sort out the two smallest distances
/*
	// Cheat and pick only F1
	d.xy = min(d.xy, d.zw);
	d.x = min(d.x, d.y);
	return d.xx; // F1 duplicated, F2 not computed
*/
	// Do it right and find both F1 and F2
	d.xy = (d.x < d.y) ? d.xy : d.yx; // Swap if smaller
	d.xz = (d.x < d.z) ? d.xz : d.zx;
	d.xw = (d.x < d.w) ? d.xw : d.wx;
	d.y = min(d.y, d.z);
	d.y = min(d.y, d.w);
	return sqrt(d.xy);
}

void fragment() 
{
	vec2 st = FRAGCOORD.xy/resolution.xy;
	vec2 F = cellular2x2(st*20.+vec2(time,0.));
	float n = 1.0-1.5*F.x;
	COLOR = vec4(n, n, n, 1.0);
}