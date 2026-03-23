import { AppShell, Badge, Container, Group, Stack, Text, Title } from '@mantine/core'
import { Head } from '@inertiajs/react'

export default function AppLayout({ children }) {
  return (
    <>
      <Head title="Minecraft Server Control Plane" />
      <AppShell padding="lg" header={{ height: 72 }}>
        <AppShell.Header>
          <Container h="100%" size="lg">
            <Group h="100%" justify="space-between">
              <Stack gap={0}>
                <Title order={3}>Minecraft Server Control Plane</Title>
                <Text c="dimmed" size="sm">
                  Single-port publishing with mc-router
                </Text>
              </Stack>
              <Badge color="teal" radius="sm" variant="light">
                Bootstrap
              </Badge>
            </Group>
          </Container>
        </AppShell.Header>

        <AppShell.Main>
          <Container size="lg">{children}</Container>
        </AppShell.Main>
      </AppShell>
    </>
  )
}
