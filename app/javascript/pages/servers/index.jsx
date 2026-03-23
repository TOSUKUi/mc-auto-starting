import { Badge, Code, Group, Paper, Stack, Text, Title } from '@mantine/core'
import { Head, Link } from '@inertiajs/react'
import AppLayout from '../../layouts/AppLayout'

export default function ServersIndex({ servers }) {
  return (
    <AppLayout>
      <Head title="Servers" />

      <Stack gap="xl">
        <Stack gap={4}>
          <Title order={1}>Servers</Title>
          <Text c="dimmed">Owned and shared Minecraft servers visible to the current user.</Text>
        </Stack>

        <Stack gap="md">
          {servers.map((server) => (
            <Paper key={server.id} p="lg" radius="md" shadow="sm" withBorder>
              <Group align="flex-start" justify="space-between">
                <Stack gap={4}>
                  <Text component={Link} fw={600} href={`/servers/${server.id}`} size="lg">
                    {server.name}
                  </Text>
                  <Text c="dimmed" size="sm">
                    <Code>{server.connection_target}</Code>
                  </Text>
                </Stack>

                <Group gap="xs">
                  <Badge color="blue" variant="light">
                    {server.access_role}
                  </Badge>
                  <Badge color="teal" variant="light">
                    {server.status}
                  </Badge>
                </Group>
              </Group>
            </Paper>
          ))}
        </Stack>
      </Stack>
    </AppLayout>
  )
}
