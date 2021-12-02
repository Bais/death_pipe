require daslib/media
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code
require pipe
require debugOut
require camera


var
    pipe : Pipe
    camera : Camera

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    pipe <- pipe_initialize()
    set_window_title("death_pipe")
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    pipe_move_user(pipe, float(get_mouse_position_delta().x) * dt)

    pipe_act(pipe, dt)

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    debug_out_start()
    setUpCamera(pipe, camera)
    camera_draw(camera)
    pipe_draw(pipe, camera)
    return
