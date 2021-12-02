require daslib/media
require camera
require debugOut
require commonMath

struct PipeVervex3D
    pos : float3
    normal : float3

let num_radius_segments = 15

struct PipePoint3D
    vertexes : PipeVervex3D[num_radius_segments]
    pos : float3
    dir : float3
    up : float3


struct Pipe
    texture : Image
    points : array<PipePoint3D>
    currentPos : float
    currentAngle : float

var
    seed4 : int4


def pipe_move_user(var pipe : Pipe; dt : float)
    pipe.currentAngle += dt

def setUpCamera(var pipe : Pipe; var camera : Camera)
    let ipos = int(pipe.currentPos)
    let t = pipe.currentPos - float(ipos)
    let pos = lerp(pipe.points[ipos].pos, pipe.points[ipos + 1].pos, t)
    let dir = normalize(lerp(pipe.points[ipos].dir, pipe.points[ipos + 1].dir, t))
    var up = normalize(lerp(pipe.points[ipos].up, pipe.points[ipos + 1].up, t))
    let quat = un_quat_from_unit_vec_ang(dir, pipe.currentAngle)
    up = quat_mul_vec(quat, up)
    camera_init(camera, pos + up * 10.0, dir, up);
        
    //camera_init(camera, float3(10, 10, 0), float3(1, 0, 0), float3(0, 1, 0))



def generateVertexes(var point : PipePoint3D)
    let radius = 3.0
    let angle = 2.0 * PI / float(num_radius_segments)
    let quat = un_quat_from_unit_vec_ang(point.dir, angle)
    var norm = point.up
    point.vertexes[0].pos = point.pos + norm * radius
    point.vertexes[0].normal = norm
    for i in range(1, num_radius_segments)
        norm = quat_mul_vec(quat, norm)
        point.vertexes[i].pos = point.pos + norm * radius
        point.vertexes[i].normal = norm
        

def pushDirection(var pipe : Pipe; prev : PipePoint3D)
    let segmentLength = 60.0
    let segments = 10

    var newpos = prev.pos
    var newdir = prev.dir
    let quat = un_quat_from_unit_vec_ang(random_unit_vector(seed4), 0.005)
    let dir = quat_mul_vec(quat, prev.dir)
    let up = quat_mul_vec(quat, prev.up)
    for i in range(0, segments + 1)
        newpos += newdir * segmentLength

        let t = float(i) / float(segments)
        newdir = fast_normalize(lerp(prev.dir, dir, t))
        let newup = fast_normalize(lerp(prev.up, up, t))
        emplace(pipe.points, [[PipePoint3D pos = newpos, dir = newdir, up = newup]])


def updateDirections(var pipe)
    while length(pipe.points) < 1000
        pushDirection(pipe, pipe.points[length(pipe.points) - 1])
        


def pipe_initialize()
    var pipe : Pipe
    randomize_seed(seed4)
    let size = 128
    var data : array<uint>
    resize(data, size * size);
    var seed = 666u
    for i in range(0, size * size)
        data[i] = uint_noise_2D(int2(i / size, i % size), seed)
    pipe.texture <- create_image(size, size / 2, data)

    emplace(pipe.points, [[PipePoint3D dir = float3(0,0,1), up = float3(0,1,0)]])
    updateDirections(pipe)
    for point in pipe.points
        generateVertexes(point)

    return <-pipe


def pipe_act(var pipe : Pipe; dt : float)
    pipe.currentPos += dt * 1.0
    if int(pipe.currentPos) >= length(pipe.points) - 1
        pipe.currentPos = 0.0

let
    line = false

def draw_segment(pipe, p1, p2)
    if line
        line(
            p1.proj.x, p1.proj.y, 
            p2.proj.x, p2.proj.y,
            0xff00ff00)
        line(
            p1.proj.x - p1.side.x, p1.proj.y - p1.side.y, 
            p2.proj.x - p2.side.x, p2.proj.y - p2.side.y,
            0xffffffff)
        line(
            p1.proj.x + p1.side.x, p1.proj.y + p1.side.y, 
            p2.proj.x + p2.side.x, p2.proj.y + p2.side.y,
            0xffffffff)
    else
        draw_quad(
            pipe.texture,
            p1.proj - p1.side, p1.proj + p1.side,
            p2.proj + p2.side, p2.proj - p2.side,
            0xffffffff)

struct PipeVervex2D
    pos : float2
    color : int4

struct PipePoint2D
    vertexes : PipeVervex2D[num_radius_segments]

def line(p1, p2; color)
    line(p1.x, p1.y, p2.x, p2.y, color)

def pipe_draw(var pipe : Pipe; camera : Camera)
    var points : array<PipePoint2D>
    let numPoints = length(pipe.points)
    resize(points, numPoints)
    var i = 0
    for point in pipe.points
        for j in range(0, num_radius_segments)
            let transformed = camera_transform(camera, point.vertexes[j].pos)
            //debug_out("{point.vertexes[j].pos}   =>   {transformed} ")
            points[i].vertexes[j].pos = transformed.xy + float2(float(get_screen_width()) * 0.5, float(get_screen_height()) * 0.5)
        ++i

    for i in range(0, numPoints)
        line(points[i].vertexes[0].pos, points[i].vertexes[num_radius_segments - 1].pos, 0xff0000ff)
        for j in range(0, num_radius_segments - 1)
            line(points[i].vertexes[j].pos, points[i].vertexes[j + 1].pos, 0xff0000ff)
    
    for i in range(0, numPoints - 1)
        for j in range(0, num_radius_segments)
            line(points[i].vertexes[j].pos, points[i + 1].vertexes[j].pos, 0xff00ff00)

