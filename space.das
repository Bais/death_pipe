require daslib/media
require camera
require debugOut
require commonMath


var texture : Image

struct Point
    pos : float3
    color : uint

var points : array<Point>

def space_init()
    var seed4 : int4
    randomize_seed(seed4)
    let pointSize = 1000
    resize(points, pointSize)
    for p in points
        p.pos = random_unit_vector(seed4) * 100.0
        p.color = 0xffffffff


def render_space(camera : Camera)
    var mycamera : Camera
    camera_init(mycamera, float3(), camera.dir, camera.up)
    camera_draw(mycamera)

    for point in points
        let pos = camera_transform(mycamera, point.pos).xyz
        if pos.z > 0.0
            set_pixel(pos.x, pos.y, point.color)