float3 linear(float3 srgb) {
	return select(
		srgb > float3(0.04045),
		pow((srgb + 0.055) / 1.055, float3(2.4)),
		srgb / 12.92,
	);
}

float3 srgb(float3 linear) {
	return select(
		linear > float3(0.0031308),
		1.055 * pow(linear, float3(1.0/2.4)) - 0.055,
		12.92 * linear,
	);
}

float2 rot_trans_mmul(float4x4 rot_trans_mat, float2 vec) {
	return mul(float2x2(rot_trans_mat), vec) + float2(rot_trans_mat[0].w, rot_trans_mat[1].w);
}

float3 rot_trans_mmul(float4x4 rot_trans_mat, float3 vec) {
	return mul(float3x3(rot_trans_mat), vec) + float3(rot_trans_mat[0].w, rot_trans_mat[1].w, rot_trans_mat[2].w);
}

float4 proj_mmul(float4x4 proj_mat, float3 view) {
	return float4(
		float2(proj_mat[0].x, proj_mat[1].y) * view.xy,
		fma(proj_mat[2].z, view.z, proj_mat[2].w),
		proj_mat[3].z * view.z
	);
}

float3 proj_inv(float4x4 inv_proj_mat, float3 ndc) {
	const float4 view_undiv = float4(
		float2(inv_proj_mat[0].x, inv_proj_mat[1].y) * ndc.xy,
		inv_proj_mat[2].w,
		fma(inv_proj_mat[3].z, ndc.z, inv_proj_mat[3].w)
	);

	return view_undiv.xyz / view_undiv.w;
}
