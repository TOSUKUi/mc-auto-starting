import { Alert, AppShell, Box, Burger, Button, Container, Group, NavLink, Paper, Stack, Text, Title } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { Head, Link, router, usePage } from '@inertiajs/react'
import { IconAlertCircle, IconCircleCheck } from '@tabler/icons-react'

function labelizeUserType(value) {
  switch (value) {
    case 'admin':
      return '管理者'
    case 'operator':
      return '運用者'
    case 'reader':
      return '閲覧者'
    default:
      return value ?? '-'
  }
}

export default function AppLayout({ children }) {
  const page = usePage()
  const [opened, { close, toggle }] = useDisclosure(false)
  const { app = {} } = page.props
  const navigation = app.navigation ?? []
  const currentUser = app.current_user
  const flash = app.flash ?? {}

  return (
    <>
      <Head title="Minecraft サーバー管理" />
      <AppShell
        padding={{ base: 'md', sm: 'lg' }}
        header={{ height: { base: 72, sm: 88 } }}
        navbar={{ width: 260, breakpoint: 'sm', collapsed: { mobile: !opened } }}
        styles={{
          main: {
            background: '#181613',
            minHeight: '100vh',
          },
          header: {
            background: '#23211d',
            borderBottom: '1px solid #3b362f',
          },
          navbar: {
            background: '#1d1b17',
            borderRight: '1px solid #3b362f',
          },
        }}
      >
        <AppShell.Header>
          <Container h="100%" size="lg">
            <Group h="100%" justify="space-between" wrap="nowrap">
              <Group gap="sm" wrap="nowrap">
                <Burger aria-label="Toggle navigation" hiddenFrom="sm" opened={opened} onClick={toggle} size="sm" />
                <Stack gap={0}>
                  <Title order={3} size="h4">
                    Minecraft サーバー
                  </Title>
                  <Text c="stone.3" size="sm" visibleFrom="sm">
                    サーバーの作成と公開先をまとめて管理
                  </Text>
                </Stack>
              </Group>

              <Group gap="sm" wrap="nowrap">
                <Paper px={{ base: 'sm', sm: 'md' }} py={8} radius="xl" style={{ background: '#2a261f', borderColor: '#4a4338' }} withBorder>
                  <Group gap="sm" wrap="nowrap">
                    <Box>
                      <Stack gap={0}>
                        <Text fw={600} size="sm">
                          {currentUser?.operator_display_name}
                        </Text>
                        <Text c="stone.4" size="xs">
                          {labelizeUserType(currentUser?.user_type)}
                        </Text>
                      </Stack>
                    </Box>
                    <Button
                      color="dirt"
                      onClick={() => router.delete('/logout')}
                      size="xs"
                      type="button"
                      variant="light"
                    >
                      ログアウト
                    </Button>
                  </Group>
                </Paper>
              </Group>
            </Group>
          </Container>
        </AppShell.Header>

        <AppShell.Navbar p="md">
          <Stack gap="md">
            <Text c="stone.5" fw={700} size="xs" tt="uppercase">
              メニュー
            </Text>
            {navigation.map((item) => (
              <NavLink
                key={item.href}
                active={page.url === item.href}
                href={item.href}
                label={item.name}
                onClick={close}
                renderRoot={(props) => <Link {...props} href={item.href} />}
                styles={{
                  root: {
                    borderRadius: '14px',
                    color: '#f1efe8',
                  },
                  label: {
                    fontWeight: 600,
                  },
                }}
              />
            ))}
          </Stack>
        </AppShell.Navbar>

        <AppShell.Main>
          <Container size="lg">
            <Stack gap="md">
              {flash.notice ? (
                <Alert color="grass" icon={<IconCircleCheck size={16} />} radius="md" variant="light">
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
