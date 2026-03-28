import { Alert, Badge, Button, Code, Divider, Grid, Group, Loader, Paper, SimpleGrid, Stack, Text, TextInput, ThemeIcon, Title } from '@mantine/core'
import { Head, Link, router } from '@inertiajs/react'
import {
  IconAlertCircle,
  IconArrowBackUp,
  IconPlayerPause,
  IconPlayerPlay,
  IconRefresh,
  IconSparkles,
  IconTrash,
  IconUsers,
  IconUserPlus,
  IconWorldWww,
} from '@tabler/icons-react'
import { useEffect, useEffectEvent, useRef, useState } from 'react'

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

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

export default function ServersShow({ server }) {
  const reloadInFlight = useRef(false)
  const [ whitelistEntries, setWhitelistEntries ] = useState([])
  const [ whitelistEnabled, setWhitelistEnabled ] = useState(true)
  const [ whitelistStagedOnly, setWhitelistStagedOnly ] = useState(false)
  const [ whitelistLoading, setWhitelistLoading ] = useState(false)
  const [ whitelistError, setWhitelistError ] = useState(null)
  const [ whitelistMutationLoading, setWhitelistMutationLoading ] = useState(false)
  const [ playerName, setPlayerName ] = useState('')
  const transitionState = isTransitioning(server.status)
  const canManageWhitelist = server.can_manage_whitelist
  const whitelistLiveMode = canManageWhitelist && server.runtime.container_state === 'running'
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

  const loadWhitelist = useEffectEvent(async () => {
    if (!canManageWhitelist) {
      setWhitelistEntries([])
      setWhitelistEnabled(true)
      setWhitelistStagedOnly(false)
      setWhitelistError(null)
      return
    }

    setWhitelistLoading(true)
    setWhitelistError(null)

    try {
      const response = await fetch(`/servers/${server.id}/whitelist.json`, {
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
        },
      })
      const body = await response.json()

      if (!response.ok) {
        throw new Error(body.error || 'ホワイトリストを取得できませんでした。')
      }

      setWhitelistEntries(body.whitelist.entries || [])
      setWhitelistEnabled(body.whitelist.enabled !== false)
      setWhitelistStagedOnly(body.whitelist.staged_only === true)
    } catch (error) {
      setWhitelistError(error.message)
    } finally {
      setWhitelistLoading(false)
    }
  })

  useEffect(() => {
    setPlayerName('')
    setWhitelistEntries([])
    setWhitelistEnabled(true)
    setWhitelistStagedOnly(false)
    setWhitelistError(null)
  }, [server.id])

  useEffect(() => {
    loadWhitelist()
  }, [loadWhitelist, canManageWhitelist, server.id])

  async function mutateWhitelist(url, { method = 'POST', body } = {}) {
    setWhitelistMutationLoading(true)
    setWhitelistError(null)

    try {
      const response = await fetch(url, {
        method,
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: body ? JSON.stringify(body) : undefined,
      })
      const payload = await response.json()

      if (!response.ok) {
        throw new Error(payload.error || 'ホワイトリスト操作に失敗しました。')
      }

      setWhitelistEntries(payload.whitelist.entries || [])
      setWhitelistEnabled(payload.whitelist.enabled !== false)
      setWhitelistStagedOnly(payload.whitelist.staged_only === true)
    } catch (error) {
      setWhitelistError(error.message)
    } finally {
      setWhitelistMutationLoading(false)
    }
  }

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

            <SimpleGrid cols={{ base: 1, md: 1 }} spacing="md">
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
            </SimpleGrid>
          </Stack>
        </Paper>

        {routeIssueMessage ? (
          <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="公開反映エラー" variant="light">
            <Stack gap="sm">
              <Text>{routeIssueMessage}</Text>
              <Text c="dimmed" size="sm">
                {server.can_repair_publication ? "まず公開設定を再適用してください。" : "この問題は管理者または運用担当に対応を依頼してください。"}
              </Text>
              {server.can_repair_publication ? (
                <Group justify="flex-start">
                  <Button
                    color="red"
                    leftSection={<IconRefresh size={16} />}
                    onClick={() => router.post(`/servers/${server.id}/repair_publication`)}
                    size="xs"
                    type="button"
                    variant="light"
                  >
                    公開設定を再適用
                  </Button>
                </Group>
              ) : null}
            </Stack>
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

        {canManageWhitelist ? (
          <Paper p="lg" radius="lg" shadow="sm" withBorder>
            <Stack gap="md">
              <Group justify="space-between" align="center">
                <Text fw={700}>ホワイトリスト</Text>
                {whitelistLoading ? <Loader size="sm" /> : null}
              </Group>
              <Divider />

              <>
                {whitelistStagedOnly ? (
                  <Alert color="blue" radius="lg" title="次回起動時に反映します" variant="light">
                    停止中のため、いまの変更は保存だけ行います。次に起動すると現在の設定で container を作り直して反映します。
                  </Alert>
                ) : null}

                {!whitelistEnabled ? (
                  <Alert color="yellow" radius="lg" title="現在は無効です" variant="light">
                    この状態では登録済みプレイヤーがいても接続制限はかかりません。
                  </Alert>
                ) : null}

                  {whitelistError ? (
                    <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="ホワイトリスト操作に失敗しました" variant="light">
                      {whitelistError}
                    </Alert>
                  ) : null}

                  <Group gap="xs">
                    <Button
                      onClick={() => mutateWhitelist(`/servers/${server.id}/enable_whitelist`)}
                      size="xs"
                      type="button"
                      variant="light"
                      disabled={whitelistMutationLoading}
                    >
                      有効化
                    </Button>
                    <Button
                      onClick={() => mutateWhitelist(`/servers/${server.id}/disable_whitelist`)}
                      size="xs"
                      type="button"
                      variant="light"
                      disabled={whitelistMutationLoading}
                    >
                      無効化
                    </Button>
                    <Button
                      leftSection={<IconRefresh size={14} />}
                      onClick={() => mutateWhitelist(`/servers/${server.id}/reload_whitelist`)}
                      size="xs"
                      type="button"
                      variant="default"
                      disabled={whitelistMutationLoading}
                    >
                      再読込
                    </Button>
                  </Group>

                  <Group align="flex-end" grow>
                    <TextInput
                      label="プレイヤー名"
                      value={playerName}
                      onChange={(event) => setPlayerName(event.currentTarget.value)}
                      placeholder="Steve"
                    />
                    <Button
                      leftSection={<IconUserPlus size={16} />}
                      onClick={() => {
                        mutateWhitelist(`/servers/${server.id}/add_whitelist_player`, {
                          body: { player_name: playerName },
                        })
                        setPlayerName('')
                      }}
                      type="button"
                      disabled={whitelistMutationLoading || playerName.trim().length === 0}
                    >
                      追加
                    </Button>
                  </Group>

                  <Stack gap="xs">
                    <Text c="dimmed" size="sm">現在の許可プレイヤー</Text>
                    {whitelistEntries.length === 0 ? (
                      <Text size="sm">まだ登録はありません。</Text>
                    ) : (
                      <Group gap="xs">
                        {whitelistEntries.map((entry) => (
                          <Badge
                            key={entry}
                            color="blue"
                            onClick={() => mutateWhitelist(`/servers/${server.id}/remove_whitelist_player`, {
                              method: 'DELETE',
                              body: { player_name: entry },
                            })}
                            style={{ cursor: whitelistMutationLoading ? 'default' : 'pointer' }}
                            variant="light"
                          >
                            {entry} ×
                          </Badge>
                        ))}
                      </Group>
                    )}
                  </Stack>
              </>
            </Stack>
          </Paper>
        ) : null}
      </Stack>
    </>
  )
}
