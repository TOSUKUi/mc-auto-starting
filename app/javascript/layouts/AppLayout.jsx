import { Alert, AppShell, Badge, Button, Container, Group, NavLink, Paper, Stack, Text, Title } from '@mantine/core'
import { Head, Link, usePage } from '@inertiajs/react'
import { IconAlertCircle, IconCircleCheck } from '@tabler/icons-react'

export default function AppLayout({ children }) {
  const page = usePage()
  const { app = {} } = page.props
  const navigation = app.navigation ?? []
  const currentUser = app.current_user
  const flash = app.flash ?? {}

  return (
    <>
      <Head title="Minecraft Server Control Plane" />
      <AppShell padding="lg" header={{ height: 88 }} navbar={{ width: 260, breakpoint: 'sm' }}>
        <AppShell.Header>
          <Container h="100%" size="lg">
            <Group h="100%" justify="space-between">
              <Stack gap={0}>
                <Title order={3}>Minecraft Server Control Plane</Title>
                <Text c="dimmed" size="sm">
                  Single-port publishing with mc-router
                </Text>
              </Stack>
              <Group gap="sm">
                <Badge color="teal" radius="sm" variant="light">
                  Authenticated
                </Badge>
                <Paper px="md" py={8} radius="xl" withBorder>
                  <Group gap="md">
                    <Stack gap={0}>
                      <Text fw={600} size="sm">
                        {currentUser?.email_address}
                      </Text>
                      <Text c="dimmed" size="xs">
                        signed in
                      </Text>
                    </Stack>
                    <Button
                      color="gray"
                      component={Link}
                      href="/logout"
                      method="delete"
                      size="xs"
                      variant="light"
                    >
                      Logout
                    </Button>
                  </Group>
                </Paper>
              </Group>
            </Group>
          </Container>
        </AppShell.Header>

        <AppShell.Navbar p="md">
          <Stack gap="xs">
            {navigation.map((item) => (
              <NavLink
                key={item.href}
                active={page.url === item.href}
                component={Link}
                href={item.href}
                label={item.name}
              />
            ))}
          </Stack>
        </AppShell.Navbar>

        <AppShell.Main>
          <Container size="lg">
            <Stack gap="md">
              {flash.notice ? (
                <Alert color="teal" icon={<IconCircleCheck size={16} />} radius="md" variant="light">
                  {flash.notice}
                </Alert>
              ) : null}
              {flash.alert ? (
                <Alert color="red" icon={<IconAlertCircle size={16} />} radius="md" variant="light">
                  {flash.alert}
                </Alert>
              ) : null}
              {children}
            </Stack>
          </Container>
        </AppShell.Main>
      </AppShell>
    </>
  )
}
