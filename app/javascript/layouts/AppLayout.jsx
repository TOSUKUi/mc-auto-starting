import { Alert, AppShell, Badge, Box, Burger, Button, Container, Group, NavLink, Paper, Stack, Text, Title } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { Head, Link, router, usePage } from '@inertiajs/react'
import { IconAlertCircle, IconCircleCheck } from '@tabler/icons-react'

export default function AppLayout({ children }) {
  const page = usePage()
  const [opened, { close, toggle }] = useDisclosure(false)
  const { app = {} } = page.props
  const navigation = app.navigation ?? []
  const currentUser = app.current_user
  const flash = app.flash ?? {}

  return (
    <>
      <Head title="Minecraft Server Control Plane" />
      <AppShell
        padding={{ base: 'md', sm: 'lg' }}
        header={{ height: { base: 72, sm: 88 } }}
        navbar={{ width: 260, breakpoint: 'sm', collapsed: { mobile: !opened } }}
      >
        <AppShell.Header>
          <Container h="100%" size="lg">
            <Group h="100%" justify="space-between" wrap="nowrap">
              <Group gap="sm" wrap="nowrap">
                <Burger aria-label="Toggle navigation" hiddenFrom="sm" opened={opened} onClick={toggle} size="sm" />
                <Stack gap={0}>
                  <Title order={3} size="h4">
                    Minecraft Server Control Plane
                  </Title>
                  <Text c="dimmed" size="sm" visibleFrom="sm">
                    Single-port publishing with mc-router
                  </Text>
                </Stack>
              </Group>

              <Group gap="sm" wrap="nowrap">
                <Badge color="teal" radius="sm" variant="light" visibleFrom="sm">
                  Authenticated
                </Badge>
                <Paper px={{ base: 'sm', sm: 'md' }} py={8} radius="xl" withBorder>
                  <Group gap="sm" wrap="nowrap">
                    <Box visibleFrom="sm">
                      <Stack gap={0}>
                        <Text fw={600} size="sm">
                          {currentUser?.email_address}
                        </Text>
                        <Text c="dimmed" size="xs">
                          signed in
                        </Text>
                      </Stack>
                    </Box>
                    <Button
                      color="gray"
                      onClick={() => router.delete('/logout')}
                      size="xs"
                      type="button"
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
                href={item.href}
                label={item.name}
                onClick={close}
                renderRoot={(props) => <Link {...props} href={item.href} />}
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
