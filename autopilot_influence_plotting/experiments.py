import numpy as np
from mayavi import mlab
from traits.api import HasTraits, Str, Button
from traitsui.api import View, Item, UItem, HGroup, spring

# Define the angular coordinates
clock_face = np.linspace(np.pi, -np.pi, 100)
forward_angle = np.linspace(0, np.pi, 50)
clock_face, forward_angle = np.meshgrid(clock_face, forward_angle)

# Spherical to Cartesian conversion for the sphere
x_sphere = np.sin(forward_angle) * np.sin(clock_face)
y_sphere = -np.sin(forward_angle) * np.cos(clock_face)
z_sphere = np.cos(forward_angle)

# Define xz plane coordinates
x_plane = np.linspace(-1, 1, 50)
z_plane = np.linspace(-1, 1, 50)
x_plane, z_plane = np.meshgrid(x_plane, z_plane)
y_plane = np.zeros_like(x_plane)  # Constant y coordinate

# Define the color function
def color_function(c, f, x, y, z, equation):
    # Example: color based on angles
    return eval(equation)

# Define a Traits UI class for the input and reset button
class EquationInput(HasTraits):
    equation = Str("c")

    reset_button = Button("Reset")

    def _reset_button_fired(self):
        c_sphere = color_function(clock_face, forward_angle, x_sphere, y_sphere, z_sphere, self.equation)
        sphere.mlab_source.scalars = c_sphere

    traits_view = View(
        HGroup(
            Item('equation', label='Equation:'),
            UItem('reset_button'),
            spring,
        ),
        resizable=True
    )

# Create a new figure
mlab.figure(size=(800, 800))

# Initialize the equation input class
eq_input = EquationInput()

# Plot the sphere
c_sphere = color_function(clock_face, forward_angle, x_sphere, y_sphere, z_sphere, eq_input.equation)
sphere = mlab.mesh(x_sphere, y_sphere, z_sphere, scalars=c_sphere, colormap='viridis')

# Plot the xz plane
plane = mlab.mesh(x_plane, y_plane, z_plane, color=(0,0,0))

# Add arrows along the y and z axes
mlab.quiver3d(0, 0, 0, 0, 2, 0, color=(0,0,0), mode='arrow', scale_factor=1)
mlab.quiver3d(0, 0, 0, 0, 0, 2, color=(0,0,0), mode='arrow', scale_factor=1)

# Function to update the plot based on the input equation
def update_plot():
    pass  # This function is empty as we don't want automatic updates

# Add a callback to update the plot when the reset button is pressed
eq_input.on_trait_change(eq_input._reset_button_fired, 'reset_button')

# Show the UI
eq_input.configure_traits()
