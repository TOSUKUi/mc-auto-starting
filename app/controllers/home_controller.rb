class HomeController < InertiaController
  def index
    render inertia: "home/index", props: {
      app_name: "Minecraft Server Control Plane",
      public_port: MinecraftPublicEndpoint.public_port,
      public_domain: MinecraftPublicEndpoint.public_domain,
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
