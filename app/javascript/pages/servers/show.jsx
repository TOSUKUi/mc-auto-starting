import { Alert, Badge, Button, Code, Divider, Grid, Group, Paper, SimpleGrid, Stack, Text, ThemeIcon, Title } from '@mantine/core'
import { Head, Link, router } from '@inertiajs/react'
import {
  IconActivityHeartbeat,
  IconAlertCircle,
  IconArrowBackUp,
  IconPlayerPause,
  IconPlayerPlay,
  IconRefresh,
  IconRoute2,
  IconServer2,
  IconTrash,
  IconUsers,
  IconWorldWww,
} from '@tabler/icons-react'

const STATUS_COLORS = {
  provisioning: 'violet',
  ready: 'teal',
  stopped: 'gray',
  starting: 'cyan',
  stopping: 'yellow',
  restarting: 'blue',
  degraded: 'orange',
  unpublished: 'red',
  failed: 'red',
  deleting: 'dark',
}

const ROUTE_COLORS = {
  success: 'teal',
  pending: 'yellow',
  failed: 'red',
}

const HEALTH_COLORS = {
  healthy: 'teal',
  unknown: 'gray',
  unreachable: 'orange',
  rejected: 'red',
}

function labelize(value) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function formatTimestamp(value) {
  if (!value) return 'Not yet'

  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function DetailLine({ label, value }) {
  return (
    <Stack gap={2}>
      <Text c="dimmed" fw={600} size="xs" tt="uppercase">
        {label}
      </Text>
      <Text>{value}</Text>
    </Stack>
  )
}

export default function ServersShow({ server }) {
  return (
    <>
      <Head title={server.name} />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{
            background:
              'linear-gradient(135deg, rgba(16,84,111,0.08) 0%, rgba(87,143,240,0.07) 45%, rgba(245,249,255,0.96) 100%)',
          }}
          withBorder
        >
          <Stack gap="lg">
            <Group justify="space-between" align="flex-start">
              <Stack gap={8}>
                <Text href="/servers" renderRoot={(props) => <Link {...props} href="/servers" />} size="sm">
                  <Group gap={6}>
                    <IconArrowBackUp size={14} />
                    <span>Back to servers</span>
                  </Group>
                </Text>
                <Group gap="xs">
                  <ThemeIcon color="cyan" radius="xl" size={36} variant="light">
                    <IconServer2 size={18} />
                  </ThemeIcon>
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">
                    Server Detail
                  </Text>
                </Group>
                <Title order={1}>{server.name}</Title>
                <Text c="dimmed" size="md">
                  {server.fqdn}
                </Text>
                <Group gap="xs">
                  <Badge color="blue" variant="light">
                    {server.access_role}
                  </Badge>
                  <Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">
                    {labelize(server.status)}
                  </Badge>
                  <Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">
                    Route {labelize(server.route.last_apply_status)}
                  </Badge>
                  <Badge color={HEALTH_COLORS[server.route.last_healthcheck_status] ?? 'gray'} variant="light">
                    Health {labelize(server.route.last_healthcheck_status)}
                  </Badge>
                </Group>
              </Stack>

              <Group gap="xs" justify="flex-end">
                {server.can_manage_members ? (
                  <Button
                    href={`/servers/${server.id}/members`}
                    leftSection={<IconUsers size={16} />}
                    renderRoot={(props) => <Link {...props} href={`/servers/${server.id}/members`} />}
                    variant="light"
                  >
                    Members
                  </Button>
                ) : null}
                {server.can_start ? (
                  <Button leftSection={<IconPlayerPlay size={16} />} onClick={() => router.post(`/servers/${server.id}/start`)} type="button" variant="light">
                    Start
                  </Button>
                ) : null}
                {server.can_stop ? (
                  <Button leftSection={<IconPlayerPause size={16} />} onClick={() => router.post(`/servers/${server.id}/stop`)} type="button" variant="light">
                    Stop
                  </Button>
                ) : null}
                {server.can_restart ? (
                  <Button leftSection={<IconRefresh size={16} />} onClick={() => router.post(`/servers/${server.id}/restart`)} type="button" variant="light">
                    Restart
                  </Button>
                ) : null}
                {server.can_sync ? (
                  <Button onClick={() => router.post(`/servers/${server.id}/sync`)} type="button" variant="default">
                    Sync
                  </Button>
                ) : null}
                {server.can_destroy ? (
                  <Button color="red" leftSection={<IconTrash size={16} />} onClick={() => router.delete(`/servers/${server.id}`)} type="button" variant="light">
                    Delete
                  </Button>
                ) : null}
              </Group>
            </Group>

            <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="blue" radius="xl" size={28} variant="light">
                      <IconWorldWww size={15} />
                    </ThemeIcon>
                    <Text fw={700}>Connection</Text>
                  </Group>
                  <Text c="dimmed" size="sm">
                    This public target is the only address players should use.
                  </Text>
                  <Code block>{server.connection_target}</Code>
                </Stack>
              </Paper>

              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="orange" radius="xl" size={28} variant="light">
                      <IconRoute2 size={15} />
                    </ThemeIcon>
                    <Text fw={700}>Route Publication</Text>
                  </Group>
                  <Text c="dimmed" size="sm">
                    Publication state on mc-router for this hostname.
                  </Text>
                  <Text fw={600}>{server.route.enabled ? 'Enabled' : 'Disabled'}</Text>
                </Stack>
              </Paper>

              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="teal" radius="xl" size={28} variant="light">
                      <IconActivityHeartbeat size={15} />
                    </ThemeIcon>
                    <Text fw={700}>Execution Backend</Text>
                  </Group>
                  <Text c="dimmed" size="sm">
                    Provider-side target currently bound to this record.
                  </Text>
                  <Code block>{server.execution.backend_host && server.execution.backend_port ? `${server.execution.backend_host}:${server.execution.backend_port}` : 'Provisioning pending'}</Code>
                </Stack>
              </Paper>
            </SimpleGrid>
          </Stack>
        </Paper>

        {server.last_error_message ? (
          <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="Last failure" variant="light">
            {server.last_error_message}
          </Alert>
        ) : null}

        <Grid gutter="md">
          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>Server Overview</Text>
                <Divider />
                <DetailLine label="Hostname" value={<Code>{server.fqdn}</Code>} />
                <DetailLine label="Minecraft Version" value={<Code>{server.minecraft_version}</Code>} />
                <DetailLine label="Template" value={<Code>{server.template_kind}</Code>} />
                <DetailLine label="Provider" value={<Code>{server.provider_name}</Code>} />
                <DetailLine label="Provider Server ID" value={<Code>{server.execution.provider_server_id ?? 'Not assigned'}</Code>} />
                <DetailLine label="Provider Identifier" value={<Code>{server.provider_server_identifier ?? 'Not assigned'}</Code>} />
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>Route State</Text>
                <Divider />
                <DetailLine label="Apply Status" value={<Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">{labelize(server.route.last_apply_status)}</Badge>} />
                <DetailLine label="Health Status" value={<Badge color={HEALTH_COLORS[server.route.last_healthcheck_status] ?? 'gray'} variant="light">{labelize(server.route.last_healthcheck_status)}</Badge>} />
                <DetailLine label="Publication" value={server.route.enabled ? 'Enabled' : 'Disabled'} />
                <DetailLine label="Last Applied" value={formatTimestamp(server.route.last_applied_at)} />
                <DetailLine label="Last Health Check" value={formatTimestamp(server.route.last_healthchecked_at)} />
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={12}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <Stack gap="md">
                <Text fw={700}>Operator Notes</Text>
                <Divider />
                <Text c="dimmed" size="sm">
                  `start` / `stop` / `restart` send lifecycle requests to the execution provider client API. `sync` fetches the latest
                  provider runtime state and reconciles this record. Route publication stays on the single shared public port.
                </Text>
                <Text c="dimmed" size="sm">
                  If provider state goes missing or conflicts with the local transition graph, this server is marked `degraded`
                  instead of pretending the old DB state is still correct.
                </Text>
              </Stack>
            </Paper>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
