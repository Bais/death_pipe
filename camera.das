require daslib/media
require debugOut

def look_at_lh ( Eye,At,Up:float3 )
    let zaxis = normalize(At - Eye)
    let xaxis = normalize(cross(Up, zaxis))
    let yaxis = cross(zaxis, xaxis)
    var tm : float4x4
    tm[0] = float4(xaxis.x,yaxis.x,zaxis.x,0.)
    tm[1] = float4(xaxis.y,yaxis.y,zaxis.y,0.)
    tm[2] = float4(xaxis.z,yaxis.z,zaxis.z,0.)
    tm[3] = float4( -dot(xaxis, Eye),
                    -dot(yaxis, Eye),
                    -dot(zaxis, Eye),1.)
    return tm

def perspective_rh ( fovy,aspect,zn,zf : float )
	let yScale = 1. / tan(fovy/2.)
    let xScale = yScale / aspect
    var Result : float4x4
    identity(Result)
    Result[0][0] = xScale
    Result[1][1] = yScale
    Result[2][2] = zf/(zn-zf)
    Result[2][3] = -1.0
    Result[3][2] = zn*zf/(zn-zf)
    return Result

struct Camera
    pos : float3
    dir : float3
    up : float3
    viewMatrix : float4x4
    projMatrix : float4x4
    viewprojMatrix : float4x4


def camera_init(var camera : Camera; pos, dir, up: float3)
    camera.pos = pos
    camera.dir = dir
    camera.up = up


def camera_draw(var camera : Camera)
    camera.viewMatrix = look_at(float4(camera.pos, 0.0), float4(camera.pos + camera.dir, 0.0), float4(camera.up, 0.0))
    camera.projMatrix = persp_forward(
      0.4,// * float(get_screen_height()),// * float(get_screen_height()) /20.0,
      0.4,// * float(get_screen_height()),// * float(get_screen_width()) / 20.0,
      0.1,
      10000.0)

    //debug_out("Camera {camera.pos}  {camera.dir} {camera.up}")   


def camera_transform(camera : Camera; point : float3)
    var res = camera.projMatrix * ( camera.viewMatrix * float4(point, 1.0) )
    res.x *= float(get_screen_height()) / res.z
    res.y *= -1.0 * float(get_screen_height()) / res.z
    res.x += float(get_screen_width()) * 0.5
    res.y += float(get_screen_height()) * 0.5
    return res


def draw_quad_3d(camera : Camera; texture : Image; p0, p1, p2, p3 : float3; color : uint)
    let p0t = camera_transform(camera, p0)
    if p0t.z < 0.0
        return
    
    let p1t = camera_transform(camera, p1)
    if p1t.z < 0.0
        return

    let p2t = camera_transform(camera, p2)
    if p2t.z < 0.0
        return
    
    let p3t = camera_transform(camera, p3)
    if p3t.z < 0.0
        return
    
    draw_quad(texture, p0t.xy, p1t.xy, p2t.xy, p3t.xy, color)