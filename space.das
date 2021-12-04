require daslib/media
require camera
require debugOut
require commonMath


var texture : Image

struct Point
    pos : float3
    size : float
    color : uint

var points : array<Point>

def space_init()
    var seed4 : int4
    randomize_seed(seed4)
    let pointSize = 1000
    resize(points, pointSize)
    for p in points
        p.pos = random_unit_vector(seed4) * 100.0
        p.size = float(random_int(seed4) % 3 + 1)
        p.color = make_color((random_float(seed4) + 1.0) * 0.5)


def render_space(camera : Camera)
    var mycamera : Camera
    camera_init(mycamera, float3(), camera.dir, camera.up)
    camera_draw(mycamera)

    for point in points
        let pos = camera_transform(mycamera, point.pos).xyz
        if pos.z > 0.0
            fill_rect(pos.x, pos.y, point.size, point.size, point.color)