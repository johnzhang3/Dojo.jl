using Dojo
using DojoEnvironments
using BenchmarkTools

# ### Select mechanism
name = :quadruped

# ### Get mechanism (check DojoEnvironments/src/mechanisms files for kwargs)
mech_no_contact = get_mechanism(name; contact_body=false, contact_feet=false)
mech_contact_feet = get_mechanism(name; contact_body=false, contact_feet=true) 
mech_contact_feet_body = get_mechanism(name; contact_body=true, contact_feet=true)


# ### Initialize mechanism (check DojoEnvironments/src/mechanisms files for kwargs)
initialize!(mech_no_contact, name)
initialize!(mech_contact_feet, name)
initialize!(mech_contact_feet_body, name)

# ### Simulate mechanism
@benchmark storage = simulate!(mech_no_contact, 1, record=false)
@benchmark storage = simulate!(mech_contact_feet, 1, record=false)
@benchmark storage = simulate!(mech_contact_feet_body, 1, record=false)
    
# ### Visualize mechanism
vis = visualize(mech, storage)
render(vis)