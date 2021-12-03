require daslib/media
require camera
require debugOut
require commonMath

struct PipeVervex3D
    pos : float3
    normal : float3
    textcoord : float2

struct PipePoint3D
    vertexes : PipeVervex3D[num_radius_segments]
    pos : float3
    dir : float3
    up : float3
    texcoord : float
    index : int


struct Pipe
    texture : Image
    points : array<PipePoint3D>
    currentPos : float
    currentAngle : float

var
    seed4 : int4

let num_radius_segments = 20
let texture_size = 1000
let directLigth = normalize(float3(1, 1, 0))

def pipe_move_user(var pipe : Pipe; dt : float)
    pipe.currentAngle += dt * 0.5

def setUpCamera(var pipe : Pipe; var camera : Camera)
    let ipos = int(pipe.currentPos)
    let t = pipe.currentPos - float(ipos)
    let pos = lerp(pipe.points[ipos].pos, pipe.points[ipos + 1].pos, t)
    let dir = normalize(lerp(pipe.points[ipos].dir, pipe.points[ipos + 1].dir, t))
    var up = normalize(lerp(pipe.points[ipos].up, pipe.points[ipos + 1].up, t))
    let quat = un_quat_from_unit_vec_ang(dir, pipe.currentAngle)
    up = quat_mul_vec(quat, up)
    camera_init(camera, pos + up * 35.0, dir * 1.0, up * 1.0);
        
    //camera_init(camera, float3(10, 10, 0), float3(1, 0, 0), float3(0, 1, 0))



def generateVertexes(var point : PipePoint3D)
    let radius = 30.0
    let angle = 2.0 * PI / float(num_radius_segments)
    let quat = un_quat_from_unit_vec_ang(point.dir, angle)
    var norm = point.up
    point.vertexes[0].pos = point.pos + norm * radius
    point.vertexes[0].normal = norm
    point.vertexes[0].textcoord = float2(0.0, point.texcoord)
    for i in range(1, num_radius_segments)
        norm = quat_mul_vec(quat, norm)
        point.vertexes[i].pos = point.pos + norm * radius
        point.vertexes[i].normal = norm
        point.vertexes[i].textcoord = float2(float(i * texture_size)/float(num_radius_segments - 1), point.texcoord)
        // point.vertexes[i].textcoord = float2(float(i * texture_size)/float(num_radius_segments - 1),
        //     float(point.index % 2 * texture_size))
        //print("{point.index} {point.vertexes[i].textcoord} \n")

let pipe_segments = 50

def pushDirection(var pipe : Pipe; prev : PipePoint3D)
    let segmentLength = 4.0

    var newpos = prev.pos
    var newdir = prev.dir
    let quat = un_quat_from_unit_vec_ang(random_unit_vector(seed4), 0.3)
    let dir = quat_mul_vec(quat, prev.dir)
    let up = quat_mul_vec(quat, prev.up)
    let uv = prev.texcoord + float(texture_size)
    for i in range(0, pipe_segments + 1)
        newpos += newdir * segmentLength

        let t = float(i) / float(pipe_segments)
        newdir = fast_normalize(lerp(prev.dir, dir, t))
        let newup = fast_normalize(lerp(prev.up, up, t))
        let newuv = lerp(prev.texcoord, uv, t)
        //let newuv = lerp(0.0, 10.0, t)
        emplace(pipe.points,
            [[PipePoint3D pos = newpos, dir = newdir, up = newup, texcoord = newuv, index = prev.index + 1]])
        generateVertexes(back(pipe.points))


def updateDirections(var pipe)
    while length(pipe.points) < pipe_segments * 10
        pushDirection(pipe, back(pipe.points))
        


def pipe_initialize()
    var pipe : Pipe
    randomize_seed(seed4)
    pipe.texture <- create_image("res/fire.jpg") 
    emplace(pipe.points, [[PipePoint3D dir = float3(0,0,1), up = float3(0,1,0)]])
    generateVertexes(back(pipe.points))
    updateDirections(pipe)
    return <-pipe


def pipe_act(var pipe : Pipe; dt : float)
    pipe.currentPos += dt * 5.0
    if (int(pipe.currentPos) > 1)
        erase(pipe.points, 0)
        pipe.currentPos -= 1.0
    updateDirections(pipe)

let
    line = false

struct PipeVervex2D
    pos : float3
    color : uint

struct PipePoint2D
    vertexes : PipeVervex2D[num_radius_segments]

def line(p1, p2; color)
    line(p1.x, p1.y, p2.x, p2.y, color)

def drawTriangle(pipe : Pipe; points : array<PipePoint2D>; camera : Camera; a, b, c : int2)
    //debug_out("{points[1]}")
    //debug_out("{points[2]}")
    let posA3D = pipe.points[a.x].vertexes[a.y].pos
    let posB3D = pipe.points[b.x].vertexes[b.y].pos
    let posC3D = pipe.points[c.x].vertexes[c.y].pos

    let norm = cross(posB3D - posA3D, posC3D - posA3D)
    //if dot(norm, camera.dir) <= 0.0
    //    return

    let posA2D = points[a.x].vertexes[a.y].pos
    let posB2D = points[b.x].vertexes[b.y].pos
    let posC2D = points[c.x].vertexes[c.y].pos
    if posA2D.z <= 0.0 || posB2D.z <= 0.0 || posC2D.z <= 0.0
        return

    let pos <- [{ float2 posA2D.xy; posB2D.xy; posC2D.xy}]
    let uv <- [{ float2 pipe.points[a.x].vertexes[a.y].textcoord; pipe.points[b.x].vertexes[b.y].textcoord; pipe.points[c.x].vertexes[c.y].textcoord}]
    let colors <- [{ uint points[a.x].vertexes[a.y].color; points[b.x].vertexes[b.y].color; points[c.x].vertexes[c.y].color}]

    //print("{uv} \n")
    //debug_out("{pos}   =>   {uv} ")
    draw_triangle_strip(pipe.texture, pos, uv, colors)
        

def pipe_draw(var pipe : Pipe; camera : Camera)
    //draw_image(pipe.texture, 0, 0)
    var points : array<PipePoint2D>
    let numPoints = length(pipe.points)
    resize(points, numPoints)
    
    var i = 0
    for point in pipe.points
        for j in range(0, num_radius_segments)
            points[i].vertexes[j].color = make_color(max(0.2, dot(point.vertexes[j].normal, directLigth)))
            //debug_out("{point.vertexes[j].pos}   =>   {transformed} ")
            points[i].vertexes[j].pos = camera_transform(camera, point.vertexes[j].pos).xyz
        ++i

    debug_out("{points[0].vertexes}")
    i = numPoints - 2
    while i >= max(0, int(pipe.currentPos) - 1)
        for j in range(0, num_radius_segments)
            let j2 = j == num_radius_segments - 1 ? 0 : j + 1
            drawTriangle(pipe, points, camera, int2(i, j), int2(i, j2), int2(i + 1, j ))
            drawTriangle(pipe, points, camera, int2(i + 1, j), int2(i, j2), int2(i + 1, j2))
        --i

    return
    for i in range(0, numPoints)
        line(points[i].vertexes[0].pos, points[i].vertexes[num_radius_segments - 1].pos, points[i].vertexes[0].color)
        for j in range(0, num_radius_segments - 1)
            line(points[i].vertexes[j].pos, points[i].vertexes[j + 1].pos, points[i].vertexes[j].color)
    
    for i in range(0, numPoints - 1)
        for j in range(0, num_radius_segments)
            line(points[i].vertexes[j].pos, points[i + 1].vertexes[j].pos, points[i].vertexes[j].color)

