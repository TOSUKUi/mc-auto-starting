import { Alert, Badge, Button, Code, Divider, Grid, Group, Loader, Paper, SimpleGrid, Stack, Text, ThemeIcon, Title } from '@mantine/core'
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
import { useEffect, useEffectEvent, useRef } from 'react'

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

const TRANSITION_STATUSES = [ 'starting', 'stopping', 'restarting' ]

function labelize(value) {
  switch (value) {
    case 'owner':
      return 'オーナー'
    case 'manager':
      return '運用担当'
    case 'viewer':
      return '閲覧のみ'
    case 'provisioning':
      return '準備中'
    case 'ready':
      return '稼働中'
    case 'stopped':
      return '停止中'
    case 'starting':
      return '起動中'
    case 'stopping':
      return '停止処理中'
    case 'restarting':
      return '再起動中'
    case 'degraded':
      return '要確認'
    case 'unpublished':
      return '非公開'
    case 'failed':
      return '失敗'
    case 'deleting':
      return '削除中'
    default:
      return value
  }
}

function runtimeFamilyLabel(value) {
  if (value === 'vanilla') return 'Vanilla'
  if (value === 'paper') return 'Paper'

  return value
}

function selectedVersionNote(server) {
  if (!server.resolved_minecraft_version) return null
  if (server.resolved_minecraft_version === server.minecraft_version) return null

  return `指定: ${server.minecraft_version}`
}

function formatTimestamp(value) {
  if (!value) return '未実行'

  return new Intl.DateTimeFormat('ja-JP', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function formatUptime(seconds) {
  if (seconds == null || seconds < 0) return '停止中'

  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  if (days > 0) return `${days}日 ${hours}時間`
  if (hours > 0) return `${hours}時間 ${minutes}分`

  return `${Math.max(minutes, 0)}分`
}

function isTransitioning(status) {
  return TRANSITION_STATUSES.includes(status)
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
  const reloadInFlight = useRef(false)
  const transitionState = isTransitioning(server.status)
  const routeIssueMessage = server.route_issue_message || (server.route.last_apply_status === 'failed' ? '公開設定の反映に失敗しています。' : null)
  const pollServer = useEffectEvent(() => {
    if (reloadInFlight.current) return

    reloadInFlight.current = true
    router.reload({
      only: [ 'server' ],
      headers: {
        'X-Server-Poll': '1',
      },
      preserveState: true,
      preserveScroll: true,
      onFinish: () => {
        reloadInFlight.current = false
      },
    })
  })

  useEffect(() => {
    reloadInFlight.current = false
  }, [server.id, server.status])

  useEffect(() => {
    if (!transitionState) return undefined

    const intervalId = window.setInterval(() => {
      pollServer()
    }, 3000)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [pollServer, transitionState])

  return (
    <>
      <Head title={server.name} />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{ background: '#26231e', borderColor: '#4a4338' }}
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
                  <Text c="stone.5" fw={700} size="sm" tt="uppercase">詳細</Text>
                </Group>
                <Title order={1} style={{ maxWidth: '100%', overflowWrap: 'anywhere', wordBreak: 'break-word' }}>{server.name}</Title>
                <Text c="stone.3" size="md" style={{ maxWidth: '100%', overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                  {server.connection_target}
                </Text>
                <Group gap="xs">
                  <Badge color="blue" variant="light">
                    {labelize(server.access_role)}
                  </Badge>
                  <Badge
                    color={STATUS_COLORS[server.status] ?? 'gray'}
                    leftSection={transitionState ? <Loader color="currentColor" size={12} type="dots" /> : null}
                    variant="light"
                  >
                    {labelize(server.status)}
                  </Badge>
                  <Badge color={ROUTE_COLORS[server.route.last_apply_status] ?? 'gray'} variant="light">
                    {server.route.enabled ? '公開中' : '非公開'}
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

            <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
              <Paper p="lg" radius="lg" withBorder>
                <Stack gap={4}>
                  <Group gap="xs">
                    <ThemeIcon color="blue" radius="xl" size={28} variant="light">
                      <IconWorldWww size={15} />
                    </ThemeIcon>
                    <Text fw={700}>接続先</Text>
                  </Group>
                  <Code block style={{ overflowWrap: 'anywhere', wordBreak: 'break-word', whiteSpace: 'pre-wrap' }}>{server.connection_target}</Code>
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
            </SimpleGrid>
          </Stack>
        </Paper>

        {routeIssueMessage ? (
          <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="公開反映エラー" variant="light">
            {routeIssueMessage}
          </Alert>
        ) : null}

        {server.last_error_message ? (
          <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="直近の失敗" variant="light">
            {server.last_error_message}
          </Alert>
        ) : null}

        <Grid gutter="md">
          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>運用情報</Text>
                <Divider />
                <DetailLine label="種類" value={<Badge color="grape" variant="light">{runtimeFamilyLabel(server.runtime_family)}</Badge>} />
                <DetailLine
                  label="Minecraft バージョン"
                  value={
                    <Stack gap={4}>
                      <Code>{server.minecraft_version_display}</Code>
                      {selectedVersionNote(server) ? <Text c="dimmed" size="sm">{selectedVersionNote(server)}</Text> : null}
                    </Stack>
                  }
                />
                <DetailLine label="オーナー" value={server.owner_display_name} />
                <DetailLine label="アクセス権" value={<Badge color="blue" variant="light">{labelize(server.access_role)}</Badge>} />
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 6 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder h="100%">
              <Stack gap="md">
                <Text fw={700}>補助情報</Text>
                <Divider />
                <DetailLine label="ホスト名" value={<Code>{server.hostname}</Code>} />
                <DetailLine label="FQDN" value={<Code>{server.fqdn}</Code>} />
                <DetailLine label="最終起動" value={formatTimestamp(server.last_started_at)} />
                <DetailLine label="連続稼働時間" value={formatUptime(server.uptime_seconds)} />
              </Stack>
            </Paper>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
