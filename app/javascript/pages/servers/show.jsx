import { Badge, Button, Code, Group, Paper, Stack, Text, Title } from '@mantine/core'
import { Head, Link } from '@inertiajs/react'

export default function ServersShow({ server }) {
  return (
    <>
      <Head title={server.name} />

      <Stack gap="xl">
        <Stack gap={4}>
          <Text component={Link} href="/servers" size="sm">
            Back to servers
          </Text>
          <Group justify="space-between">
            <Stack gap={0}>
              <Title order={1}>{server.name}</Title>
              <Text c="dimmed">{server.fqdn}</Text>
            </Stack>
            <Group gap="xs">
              {server.can_manage_members ? (
                <Button component={Link} href={`/servers/${server.id}/members`} variant="light">
                  Members
                </Button>
              ) : null}
              {server.can_start ? (
                <Button component={Link} href={`/servers/${server.id}/start`} method="post" as="button" variant="light">
                  Start
                </Button>
              ) : null}
              {server.can_stop ? (
                <Button component={Link} href={`/servers/${server.id}/stop`} method="post" as="button" variant="light">
                  Stop
                </Button>
              ) : null}
              {server.can_restart ? (
                <Button component={Link} href={`/servers/${server.id}/restart`} method="post" as="button" variant="light">
                  Restart
                </Button>
              ) : null}
              {server.can_sync ? (
                <Button component={Link} href={`/servers/${server.id}/sync`} method="post" as="button" variant="default">
                  Sync
                </Button>
              ) : null}
              {server.can_destroy ? (
                <Button component={Link} href={`/servers/${server.id}`} method="delete" as="button" color="red" variant="light">
                  Delete
                </Button>
              ) : null}
              <Badge color="blue" variant="light">
                {server.access_role}
              </Badge>
              <Badge color="teal" variant="light">
                {server.status}
              </Badge>
            </Group>
          </Group>
        </Stack>

        <Paper p="lg" radius="md" shadow="sm" withBorder>
          <Stack gap="sm">
            <Text>
              Connection target: <Code>{server.connection_target}</Code>
            </Text>
            <Text>
              Version: <Code>{server.minecraft_version}</Code>
            </Text>
            <Text>
              Template: <Code>{server.template_kind}</Code>
            </Text>
            <Text>
              Provider: <Code>{server.provider_name}</Code>
            </Text>
          </Stack>
        </Paper>
      </Stack>
    </>
  )
}
