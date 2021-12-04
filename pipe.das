require daslib/media
require camera
require debugOut
require commonMath

struct PipeVervex3D
    pos : float3
    normal : float3
    color : uint
    textcoord : float2

struct PipePoint3D
    vertexes : PipeVervex3D[num_radius_segments + 1]
    pos : float3
    dir : float3
    up : float3
    texcoord : float    
    index : int
    obstacle : int

struct Section
    points : array<PipePoint3D>

struct Pipe
    texture : Image
    obstacle : Image
    sections : array<Section?>
    currentPos : float
    currentAngle : float

var
    seed4 : int4

let pipe_radius = 30.0
let pipe_segments = 20
let num_radius_segments = 30
let texture_size = 1000

def check_collision(pipe : Pipe)
    let ipos = int(pipe.currentPos)
    let obstInd = pipe.sections[0].points[ipos].obstacle
    if obstInd < 0
        return false
    
    let obstAngle = float(obstInd) / float(num_radius_segments)
    return abs(obstAngle - pipe.currentAngle / (2.0 * PI)) < 1.0 / float(num_radius_segments)

def pipe_move_user(var pipe : Pipe; dt : float)
    pipe.currentAngle += dt * 10.0
    if pipe.currentAngle < 0.0
        pipe.currentAngle += 2.0 * PI
    elif pipe.currentAngle > 2.0 * PI
        pipe.currentAngle -= 2.0 * PI

def setUpCamera(var pipe : Pipe; var camera : Camera)
    let ipos = int(pipe.currentPos)
    let t = pipe.currentPos - float(ipos)
    let pos = lerp(pipe.sections[0].points[ipos].pos, pipe.sections[0].points[ipos + 1].pos, t)
    let dir = normalize(lerp(pipe.sections[0].points[ipos].dir, pipe.sections[0].points[ipos + 1].dir, t))
    var up = normalize(lerp(pipe.sections[0].points[ipos].up, pipe.sections[0].points[ipos + 1].up, t))
    let quat = un_quat_from_unit_vec_ang(dir, pipe.currentAngle)
    up = quat_mul_vec(quat, up)
    camera_init(camera, pos + up * 45.0, dir * 1.0, up * 1.0);



def generateVertexes(var point : PipePoint3D)
    let angle = 2.0 * PI / float(num_radius_segments)
    let quat = un_quat_from_unit_vec_ang(point.dir, angle)
    var norm = point.up
    point.vertexes[0].pos = point.pos + norm * pipe_radius
    point.vertexes[0].normal = norm
    point.vertexes[0].color = calc_light(norm)
    point.vertexes[0].textcoord = float2(0.0, point.texcoord)
    for i in range(1, num_radius_segments)
        norm = quat_mul_vec(quat, norm)
        point.vertexes[i].pos = point.pos + norm * pipe_radius
        point.vertexes[i].normal = norm
        point.vertexes[i].color = calc_light(norm)
        point.vertexes[i].textcoord = float2(float(i * texture_size)/float(num_radius_segments), point.texcoord)
    
    point.vertexes[num_radius_segments] = point.vertexes[0]
    point.vertexes[num_radius_segments].textcoord = float2(float(texture_size), point.texcoord)

def pushDirection(var pipe : Pipe; var section : Section; prev : PipePoint3D)
    let segmentLength = 2.0 * PI * pipe_radius / float(pipe_segments)

    var newpos = prev.pos
    var newdir = prev.dir
    let quat = un_quat_from_unit_vec_ang(random_unit_vector(seed4), 0.5)
    let dir = quat_mul_vec(quat, prev.dir)
    let up = quat_mul_vec(quat, prev.up)
    for i in range(0, pipe_segments)
        newpos += newdir * segmentLength

        let t = float(i + 1) / float(pipe_segments)
        newdir = fast_normalize(lerp(prev.dir, dir, t))
        let newup = fast_normalize(lerp(prev.up, up, t))
        let newuv = lerp(1.0, float(texture_size), t)
        let obstacle = random_int(seed4) < 10000 ? random_int(seed4) % pipe_segments : -1
        emplace(section.points,
            [[PipePoint3D pos = newpos, dir = newdir, up = newup, texcoord = newuv, index = prev.index + 1, obstacle = obstacle]])
        generateVertexes(back(section.points))

def pushSection(var pipe : Pipe;  prev : PipePoint3D)
    var section = new Section
    push_clone(section.points, prev)
    section.points[0].texcoord = 0.0
    section.points[0].obstacle = -1
    for v in section.points[0].vertexes
        v.textcoord.y = 0.0

    pushDirection(pipe, *section, section.points[0])
    push(pipe.sections, section)


def updateDirections(var pipe)
    while length(pipe.sections) <  20
        pushSection(pipe, back(back(pipe.sections).points))
        


def pipe_initialize()
    var pipe : Pipe
    randomize_seed(seed4)
    pipe.texture <- create_image("res/metal.jpg")
    pipe.obstacle <- create_image("res/obst.jpg")
    pushSection(pipe, [[PipePoint3D dir = float3(0,0,1), up = float3(0,1,0)]])
    updateDirections(pipe)
    return <-pipe


def pipe_act(var pipe : Pipe; dt : float)
    pipe.currentPos += dt * 10.0
    if (int(pipe.currentPos) >= pipe_segments)        
        erase(pipe.sections, 0)
        pipe.currentPos -= float(pipe_segments)
    updateDirections(pipe)

let
    line = false

struct PipePoint2D
    vertexes : float3[num_radius_segments + 1]

def drawTriangle(var pipe : Pipe; points3d : array<PipePoint3D>; points : array<PipePoint2D>; camera : Camera; a, b, c : int2)
    let posA3D = points3d[a.x].vertexes[a.y].pos
    let posB3D = points3d[b.x].vertexes[b.y].pos
    let posC3D = points3d[c.x].vertexes[c.y].pos

    let norm = cross(posB3D - posA3D, posC3D - posA3D)
    //if dot(norm, camera.dir) <= 0.0
    //    return

    let posA2D = points[a.x].vertexes[a.y]
    let posB2D = points[b.x].vertexes[b.y]
    let posC2D = points[c.x].vertexes[c.y]
    if posA2D.z <= 0.0 || posB2D.z <= 0.0 || posC2D.z <= 0.0
        return

    let pos <- [{ float2 posA2D.xy; posB2D.xy; posC2D.xy}]
    let uv <- [{ float2 points3d[a.x].vertexes[a.y].textcoord; points3d[b.x].vertexes[b.y].textcoord; points3d[c.x].vertexes[c.y].textcoord}]
    let colors <- [{ uint points3d[a.x].vertexes[a.y].color; points3d[b.x].vertexes[b.y].color; points3d[c.x].vertexes[c.y].color}]
    draw_triangle_strip(pipe.texture, pos, uv, colors)

def fill_circle(pos; radius; color)
    fill_circle(pos.x, pos.y, radius, color)

def draw_obstacle(pipe: Pipe; point: PipePoint3D; camera : Camera)
    if (point.obstacle < 0)
        return
    
    let up = normalize(point.vertexes[point.obstacle].pos - point.pos) * 20.0
    let pos1 = point.obstacle == 0 ? point.vertexes[num_radius_segments - 2].pos : point.vertexes[point.obstacle - 1].pos
    let pos2 = point.vertexes[point.obstacle + 1].pos
    draw_quad_3d(camera, pipe.obstacle, pos1, pos1 + up, pos2 + up, pos2, calc_light(-point.dir, 0.6))


def pipe_draw_section(var pipe : Pipe; section :Section; camera : Camera; var points : array<PipePoint2D>; index : int)
    let numPoints = length(section.points)
    var i = 0
    for point in section.points
        for j in range(0, num_radius_segments + 1)
            points[i].vertexes[j] = camera_transform(camera, point.vertexes[j].pos).xyz
        ++i

    i = numPoints - 2
    let limit = index == 0 ? int(pipe.currentPos) + 1 : 0
    while i >= limit
        for j in range(0, num_radius_segments)
            //let j2 = j == num_radius_segments - 1 ? 0 : j + 1
            let j2 = j + 1
            drawTriangle(pipe, section.points, points, camera, int2(i, j), int2(i, j2), int2(i + 1, j ))
            drawTriangle(pipe, section.points, points, camera, int2(i + 1, j), int2(i, j2), int2(i + 1, j2))

        draw_obstacle(pipe, section.points[i], camera)
        --i

def pipe_draw(var pipe : Pipe; camera : Camera)
    var points : array<PipePoint2D>
    resize(points, pipe_segments + 1)
    var i = length(pipe.sections) - 1
    while i >= 0
        pipe_draw_section(pipe, *pipe.sections[i], camera, points, i)
        --i