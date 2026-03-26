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
  IconSparkles,
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
  if (!value) return '未実行'

  return new Intl.DateTimeFormat('ja-JP', {
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
      <Text component="div">{value}</Text>
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
                    <span>一覧へ戻る</span>
                  </Group>
                </Text>
                <Group gap="xs">
                  <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                    <IconSparkles size={18} />
                  </ThemeIcon>
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">Server Detail</Text>
                </Group>
                <Title order={1}>{server.name}</Title>
                <Text c="dimmed" size="md" style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                  {server.connection_target}
                </Text>
                <Group gap="xs">
                  <Badge color="blue" variant="light">
                    {server.access_role}
                  </Badge>
                  <Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">
                    {labelize(server.status)}
                  </Badge>
                  <Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">
                    {server.route.enabled ? '公開中' : '非公開'}
                  </Badge>
                  <Badge color={HEALTH_COLORS[server.route.last_healthcheck_status] ?? 'gray'} variant="light">
                    応答 {labelize(server.route.last_healthcheck_status)}
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
                    メンバー
                  </Button>
                ) : null}
                {server.can_start ? (
                  <Button leftSection={<IconPlayerPlay size={16} />} onClick={() => router.post(`/servers/${server.id}/start`)} type="button" variant="light">
                    起動
                  </Button>
                ) : null}
                {server.can_stop ? (
                  <Button leftSection={<IconPlayerPause size={16} />} onClick={() => router.post(`/servers/${server.id}/stop`)} type="button" variant="light">
                    停止
                  </Button>
                ) : null}
                {server.can_restart ? (
                  <Button leftSection={<IconRefresh size={16} />} onClick={() => router.post(`/servers/${server.id}/restart`)} type="button" variant="light">
                    再起動
                  </Button>
                ) : null}
                {server.can_sync ? (
                  <Button onClick={() => router.post(`/servers/${server.id}/sync`)} type="button" variant="default">
                    同期
                  </Button>
                ) : null}
                {server.can_destroy ? (
                  <Button color="red" leftSection={<IconTrash size={16} />} onClick={() => router.delete(`/servers/${server.id}`)} type="button" variant="light">
                    削除
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
                    <Text fw={700}>接続先</Text>
                  </Group>
                  <Code block>{server.connection_target}</Code>
                </Stack>
              </Paper>

              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="orange" radius="xl" size={28} variant="light">
                      <IconRoute2 size={15} />
                    </ThemeIcon>
                    <Text fw={700}>公開状態</Text>
                  </Group>
                  <Text fw={600}>{server.route.enabled ? 'プレイヤーから接続できます' : '現在は公開されていません'}</Text>
                </Stack>
              </Paper>

              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="teal" radius="xl" size={28} variant="light">
                      <IconActivityHeartbeat size={15} />
                    </ThemeIcon>
                    <Text fw={700}>最終起動</Text>
                  </Group>
                  <Text fw={600}>{formatTimestamp(server.last_started_at)}</Text>
                </Stack>
              </Paper>
            </SimpleGrid>
          </Stack>
        </Paper>

        {server.last_error_message ? (
          <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="直近の失敗" variant="light">
            {server.last_error_message}
          </Alert>
        ) : null}

        <Grid gutter="md">
          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>サーバー情報</Text>
                <Divider />
                <DetailLine label="接続先" value={<Code>{server.connection_target}</Code>} />
                <DetailLine label="アドレス" value={<Code>{server.fqdn}</Code>} />
                <DetailLine label="Minecraft バージョン" value={<Code>{server.minecraft_version}</Code>} />
                <DetailLine label="アクセス権" value={<Badge color="blue" variant="light">{server.access_role}</Badge>} />
                <DetailLine label="現在の状態" value={<Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">{labelize(server.status)}</Badge>} />
                <DetailLine label="最終起動" value={formatTimestamp(server.last_started_at)} />
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>公開情報</Text>
                <Divider />
                <DetailLine label="公開状態" value={<Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">{server.route.enabled ? '公開中' : '非公開'}</Badge>} />
                <DetailLine label="応答状態" value={<Badge color={HEALTH_COLORS[server.route.last_healthcheck_status] ?? 'gray'} variant="light">{labelize(server.route.last_healthcheck_status)}</Badge>} />
                <DetailLine label="公開" value={server.route.enabled ? '有効' : '無効'} />
                <DetailLine label="最終反映" value={formatTimestamp(server.route.last_applied_at)} />
                <DetailLine label="最終ヘルスチェック" value={formatTimestamp(server.route.last_healthchecked_at)} />
              </Stack>
            </Paper>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
