import {
  Badge,
  Button,
  Card,
  Code,
  Divider,
  Group,
  Paper,
  SimpleGrid,
  Stack,
  Table,
  Text,
  TextInput,
  ThemeIcon,
  Title,
} from '@mantine/core'
import { Head, Link } from '@inertiajs/react'
import { IconAlertTriangle, IconSearch, IconServer2, IconWorldWww } from '@tabler/icons-react'
import { useState } from 'react'

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

function routeLabel(route) {
  return `${labelize(route.last_apply_status)} / ${labelize(route.last_healthcheck_status)}`
}

function executionLabel(execution) {
  if (execution.backend_host && execution.backend_port) {
    return `${execution.backend_host}:${execution.backend_port}`
  }

  if (execution.provider_server_id) {
    return `Provider id ${execution.provider_server_id}`
  }

  return 'Provisioning pending'
}

function needsAttention(server) {
  return server.status !== 'ready' || server.route.last_apply_status === 'failed'
}

function StatCard({ label, value, tone = 'gray' }) {
  return (
    <Card padding="lg" radius="lg" withBorder>
      <Stack gap={6}>
        <Text c="dimmed" fw={600} size="xs" tt="uppercase">
          {label}
        </Text>
        <Text fw={800} size="2rem">
          {value}
        </Text>
        <Divider color={`${tone}.2`} />
      </Stack>
    </Card>
  )
}

export default function ServersIndex({ servers, summary }) {
  const [query, setQuery] = useState('')
  const normalizedQuery = query.trim().toLowerCase()
  const filteredServers = normalizedQuery
    ? servers.filter((server) =>
        [
          server.name,
          server.hostname,
          server.fqdn,
          server.connection_target,
          server.minecraft_version,
          server.owner_email_address,
          server.access_role,
          server.status,
        ].some((value) => value?.toLowerCase().includes(normalizedQuery)),
      )
    : servers

  return (
    <>
      <Head title="Servers" />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{
            background:
              'linear-gradient(135deg, rgba(11,106,136,0.08) 0%, rgba(84,160,255,0.05) 48%, rgba(245,249,255,0.9) 100%)',
          }}
          withBorder
        >
          <Stack gap="lg">
            <Group align="flex-start" justify="space-between">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="cyan" radius="xl" size={36} variant="light">
                    <IconWorldWww size={18} />
                  </ThemeIcon>
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">
                    Server Directory
                  </Text>
                </Group>
                <Title order={1}>Servers</Title>
                <Text c="dimmed" maw={720} size="md">
                  Owned and shared Minecraft servers visible to the current user. Connection targets are always shown in the
                  public `hostname:port` format.
                </Text>
                <Text c="dimmed" size="sm">
                  Search stays local. Creation is routed through the new server draft screen, but the provider call is still
                  blocked behind `T-500`.
                </Text>
              </Stack>

              <Button
                href="/servers/new"
                renderRoot={(props) => <Link {...props} href="/servers/new" />}
                variant="gradient"
                gradient={{ from: 'blue', to: 'cyan' }}
              >
                New server
              </Button>
            </Group>

            <SimpleGrid cols={{ base: 2, md: 5 }} spacing="md">
              <StatCard label="Visible" tone="blue" value={summary.total} />
              <StatCard label="Owned" tone="teal" value={summary.owned} />
              <StatCard label="Shared" tone="cyan" value={summary.member} />
              <StatCard label="Ready" tone="green" value={summary.ready} />
              <StatCard label="Needs Attention" tone="orange" value={summary.attention_needed} />
            </SimpleGrid>
          </Stack>
        </Paper>

        <Paper p="lg" radius="lg" withBorder>
          <Group justify="space-between">
            <TextInput
              leftSection={<IconSearch size={16} />}
              onChange={(event) => setQuery(event.currentTarget.value)}
              placeholder="Filter by name, hostname, version, owner, or role"
              value={query}
              w={{ base: '100%', sm: 360 }}
            />
            <Stack align="flex-end" gap={2}>
              <Text c="dimmed" size="sm">
                Showing {filteredServers.length} of {servers.length}
              </Text>
              <Text c="dimmed" size="xs">
                Connection target is always `hostname:port`.
              </Text>
            </Stack>
          </Group>
        </Paper>

        {filteredServers.length === 0 ? (
          <Paper p="xl" radius="lg" withBorder>
            <Stack align="center" gap="sm" py="xl">
              <ThemeIcon color="gray" radius="xl" size={48} variant="light">
                <IconServer2 size={24} />
              </ThemeIcon>
              <Title order={3}>{servers.length === 0 ? 'No visible servers yet' : 'No servers matched this filter'}</Title>
              <Text c="dimmed" ta="center">
                {servers.length === 0
                  ? 'Server records will appear here once you own a server or are added as a member.'
                  : 'Adjust the search term to see the matching server records again.'}
              </Text>
            </Stack>
          </Paper>
        ) : (
          <Stack gap="md">
            {filteredServers.map((server) => (
              <Paper key={server.id} p="lg" radius="lg" shadow="sm" withBorder>
                <Stack gap="md">
                  <Group align="flex-start" justify="space-between">
                    <Stack gap={4}>
                      <Group gap="sm">
                        <Text
                          href={`/servers/${server.id}`}
                          fw={700}
                          renderRoot={(props) => <Link {...props} href={`/servers/${server.id}`} />}
                          size="lg"
                        >
                          {server.name}
                        </Text>
                        <Badge color="blue" variant="light">
                          {server.access_role}
                        </Badge>
                        <Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">
                          {labelize(server.status)}
                        </Badge>
                      </Group>
                      <Text c="dimmed" size="sm">
                        Hostname <Code>{server.fqdn}</Code>
                      </Text>
                      <Text size="sm">
                        Connection target <Code>{server.connection_target}</Code>
                      </Text>
                    </Stack>

                    {needsAttention(server) ? (
                      <Badge color="orange" leftSection={<IconAlertTriangle size={12} />} variant="light">
                        Attention
                      </Badge>
                    ) : null}
                  </Group>

                  <Table highlightOnHover horizontalSpacing="md" verticalSpacing="sm">
                    <Table.Tbody>
                      <Table.Tr>
                        <Table.Th>Version</Table.Th>
                        <Table.Td>{server.minecraft_version}</Table.Td>
                        <Table.Th>Owner</Table.Th>
                        <Table.Td>{server.owner_email_address}</Table.Td>
                      </Table.Tr>
                      <Table.Tr>
                        <Table.Th>Route</Table.Th>
                        <Table.Td>
                          <Group gap="xs">
                            <Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">
                              {labelize(server.route.last_apply_status)}
                            </Badge>
                            <Badge color={HEALTH_COLORS[server.route.last_healthcheck_status] ?? 'gray'} variant="light">
                              {labelize(server.route.last_healthcheck_status)}
                            </Badge>
                          </Group>
                        </Table.Td>
                        <Table.Th>Execution</Table.Th>
                        <Table.Td>
                          <Code>{executionLabel(server.execution)}</Code>
                        </Table.Td>
                      </Table.Tr>
                      <Table.Tr>
                        <Table.Th>Route enabled</Table.Th>
                        <Table.Td>{server.route.enabled ? 'Enabled' : 'Disabled'}</Table.Td>
                        <Table.Th>Updated</Table.Th>
                        <Table.Td>{formatTimestamp(server.updated_at)}</Table.Td>
                      </Table.Tr>
                    </Table.Tbody>
                  </Table>

                  <Group c="dimmed" gap="lg" justify="space-between">
                    <Text size="sm">Apply / health: {routeLabel(server.route)}</Text>
                    <Text size="sm">
                      Last route sync: {formatTimestamp(server.route.last_applied_at)} / check:{' '}
                      {formatTimestamp(server.route.last_healthchecked_at)}
                    </Text>
                  </Group>
                </Stack>
              </Paper>
            ))}
          </Stack>
        )}
      </Stack>
    </>
  )
}
