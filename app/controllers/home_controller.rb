class HomeController < InertiaController
  def index
    render inertia: "home/index", props: {
      app_name: "Minecraft Server Control Plane",
      public_port: 42_434,
      stack: [
        "Rails 8.1.2",
        "Inertia.js",
        "React",
        "Mantine 8.3.1",
        "Vite",
        "MariaDB 10.11.16",
      ],
    }
  end
end
