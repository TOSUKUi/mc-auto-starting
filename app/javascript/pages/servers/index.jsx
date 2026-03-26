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
  if (!value) return '未更新'

  return new Intl.DateTimeFormat('ja-JP', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function routeLabel(route) {
  return `${labelize(route.last_apply_status)} / ${labelize(route.last_healthcheck_status)}`
}

function runtimeLabel(runtime) {
  if (runtime.container_state) {
    return labelize(runtime.container_state)
  }

  if (runtime.container_id || runtime.container_name) {
    return 'Provisioned'
  }

  return 'Provisioning Pending'
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
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">Direct Docker</Text>
                </Group>
                <Title order={1}>サーバー一覧</Title>
                <Text c="dimmed" maw={720} size="md">自分が所有しているサーバーと共有されているサーバーを確認できます。</Text>
              </Stack>

              <Button
                href="/servers/new"
                renderRoot={(props) => <Link {...props} href="/servers/new" />}
                variant="gradient"
                gradient={{ from: 'blue', to: 'cyan' }}
              >
                新しいサーバー
              </Button>
            </Group>

            <SimpleGrid cols={{ base: 2, md: 5 }} spacing="md">
              <StatCard label="表示中" tone="blue" value={summary.total} />
              <StatCard label="所有" tone="teal" value={summary.owned} />
              <StatCard label="共有" tone="cyan" value={summary.member} />
              <StatCard label="稼働中" tone="green" value={summary.ready} />
              <StatCard label="要確認" tone="orange" value={summary.attention_needed} />
            </SimpleGrid>
          </Stack>
        </Paper>

        <Paper p="lg" radius="lg" withBorder>
          <Group justify="space-between">
            <TextInput
              leftSection={<IconSearch size={16} />}
              onChange={(event) => setQuery(event.currentTarget.value)}
              placeholder="名前、ホスト名、バージョン、所有者で絞り込み"
              value={query}
              w={{ base: '100%', sm: 360 }}
            />
            <Stack align="flex-end" gap={2}>
              <Text c="dimmed" size="sm">
                {filteredServers.length} / {servers.length} 件を表示
              </Text>
              <Text c="dimmed" size="xs">
                接続先は常に `hostname:port` です。
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
              <Title order={3}>{servers.length === 0 ? '表示できるサーバーがありません' : '条件に一致するサーバーがありません'}</Title>
              <Text c="dimmed" ta="center">
                {servers.length === 0
                  ? '自分が所有するか、メンバーとして追加されたサーバーがここに表示されます。'
                  : '検索条件を変更すると一致するサーバーを再表示できます。'}
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
                        要確認
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
                        <Table.Th>公開状態</Table.Th>
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
                        <Table.Th>Container</Table.Th>
                        <Table.Td>
                          <Group gap="xs">
                            <Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">
                              {runtimeLabel(server.runtime)}
                            </Badge>
                            <Code>{server.runtime.container_name}</Code>
                          </Group>
                        </Table.Td>
                      </Table.Tr>
                      <Table.Tr>
                        <Table.Th>公開</Table.Th>
                        <Table.Td>{server.route.enabled ? '有効' : '無効'}</Table.Td>
                        <Table.Th>Updated</Table.Th>
                        <Table.Td>{formatTimestamp(server.updated_at)}</Table.Td>
                      </Table.Tr>
                    </Table.Tbody>
                  </Table>

                  <Group c="dimmed" gap="lg" justify="space-between">
                    <Text size="sm">公開状態: {routeLabel(server.route)}</Text>
                    <Text size="sm">最終反映: {formatTimestamp(server.route.last_applied_at)}</Text>
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
