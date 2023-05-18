using Dojo
using DojoEnvironments

function no_controller!(environment, k)
    # x = get_state(environment)
    u = zeros(12)
    set_input!(environment, u)
end

function standing_pd!(environment, k)

    hip_angle=0; thigh_angle=pi/4; calf_angle=-pi/2
    x = get_state(environment)
    u = zeros(12)
    for i=1:4

        θ1 = x[12+(i-1)*6+1]
       dθ1 = x[12+(i-1)*6+2]
        θ2 = x[12+(i-1)*6+3]
       dθ2 = x[12+(i-1)*6+4]
        θ3 = x[12+(i-1)*6+5]
       dθ3 = x[12+(i-1)*6+6]


        u[(i-1)*3+1] = Kp[1]*(0-θ1) + Kd[1]*(0-dθ1)
        u[(i-1)*3+2] = Kp[2]*(thigh_angle-θ2) + Kd[2]*(0-dθ2)
        u[(i-1)*3+3] = Kp[3]*(calf_angle-θ3) + Kd[3]*(0-dθ3)
       

    end
    set_input!(environment, u)
end

Kp = [100;80;60]
Kd = [5;4;3]

env = get_environment(:quadruped_sampling; horizon=1000, timestep=0.001)
# simulate!(env, no_controller!; record=true)
simulate!(env, standing_pd!; record=true)
vis = visualize(env)
render(vis)