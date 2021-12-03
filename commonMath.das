require daslib/media public

def interpolate(p0, p1, p2, p3; t : float)
    let t2 = t * t
    let t3 = t2 * t
    let ti = 1.0 - t
    let ti2 = ti * ti
    let ti3 = ti2 * ti
    
    return ti3 * p0 + 3.0 * t * ti2 * p1 + 3.0 * t2 * ti * p2 + t3 * p3

def rotateDir(quat : float4; dir : float3)
    let inv = quat_conjugate(quat)
    return quat_mul(quat_mul(quat, float4(dir, 0.0)), inv).xyz