import { Alert, Badge, Button, Code, Divider, Grid, Group, Loader, Paper, ScrollArea, Select, SimpleGrid, Stack, Text, TextInput, ThemeIcon, Title } from '@mantine/core'
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
  if (value === 'vanilla') return 'Java Edition'
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

function playerCountLabel(playerPresence) {
  if (!playerPresence?.available) return null
  if (playerPresence.max_players == null) return `${playerPresence.online_count}人`

  return `${playerPresence.online_count} / ${playerPresence.max_players}人`
}

function isTransitioning(status) {
  return TRANSITION_STATUSES.includes(status)
}

function toSelectBoolean(value) {
  return value ? 'true' : 'false'
}

const DIFFICULTY_OPTIONS = [
  { value: 'peaceful', label: 'Peaceful' },
  { value: 'easy', label: 'Easy' },
  { value: 'normal', label: 'Normal' },
  { value: 'hard', label: 'Hard' },
]

const WEATHER_OPTIONS = [
  { value: 'clear', label: '晴れ' },
  { value: 'rain', label: '雨' },
  { value: 'thunder', label: '雷雨' },
]

const TIME_OPTIONS = [
  { value: 'day', label: '朝' },
  { value: 'noon', label: '昼' },
  { value: 'night', label: '夜' },
  { value: 'midnight', label: '深夜' },
]

function startupValueLabel(setting, value) {
  if (setting === 'difficulty') return DIFFICULTY_OPTIONS.find((option) => option.value === value)?.label || value
  if (setting === 'pvp') return toSelectBoolean(value) === 'true' ? '有効' : '無効'
  if (setting === 'hardcore') return value ? '有効' : '無効'
  if (setting === 'gamemode') {
    switch (value) {
      case 'survival': return 'Survival'
      case 'creative': return 'Creative'
      case 'adventure': return 'Adventure'
      case 'spectator': return 'Spectator'
      default: return value
    }
  }

  return value
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

async function readJsonResponse(response, fallbackMessage) {
  const contentType = response.headers.get('content-type') || ''

  if (!contentType.includes('application/json')) {
    throw new Error(fallbackMessage)
  }

  return response.json()
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
  const [ playerPresence, setPlayerPresence ] = useState(server.player_presence)
  const [ playerPresenceLoading, setPlayerPresenceLoading ] = useState(false)
  const [ recentLogs, setRecentLogs ] = useState({ available: false, lines: [], error_code: null })
  const [ recentLogsLoading, setRecentLogsLoading ] = useState(false)
  const [ recentLogsError, setRecentLogsError ] = useState(null)
  const [ rconLoading, setRconLoading ] = useState(false)
  const [ rconResult, setRconResult ] = useState(null)
  const [ rconError, setRconError ] = useState(null)
  const [ sayMessage, setSayMessage ] = useState('')
  const [ kickPlayerName, setKickPlayerName ] = useState('')
  const [ kickReason, setKickReason ] = useState('')
  const [ selectedDifficulty, setSelectedDifficulty ] = useState(server.startup_settings.difficulty)
  const [ selectedWeather, setSelectedWeather ] = useState('clear')
  const [ selectedTime, setSelectedTime ] = useState('day')
  const [ selectedGamemode, setSelectedGamemode ] = useState('survival')
  const [ gamemodePlayerName, setGamemodePlayerName ] = useState('')
  const transitionState = isTransitioning(server.status)
  const canManageWhitelist = server.can_manage_whitelist
  const canRunRconCommand = server.can_run_rcon_command
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
    setPlayerPresence(server.player_presence)
  }, [server.id, server.player_presence])

  useEffect(() => {
    if (!transitionState) return undefined

    const intervalId = window.setInterval(() => {
      pollServer()
    }, 3000)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [transitionState, server.id])

  const loadPlayerPresence = useEffectEvent(async () => {
    if (server.runtime.container_state !== 'running') {
      setPlayerPresence(server.player_presence)
      return
    }

    setPlayerPresenceLoading(true)

    try {
      const response = await fetch(`/servers/${server.id}/player_presence.json`, {
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
        },
      })
      const body = await readJsonResponse(response, 'プレイヤー数の取得に失敗しました。')

      if (!response.ok) {
        throw new Error(body.error || 'プレイヤー数を取得できませんでした。')
      }

      setPlayerPresence(body.player_presence)
    } catch (_error) {
      setPlayerPresence({ available: false, error_code: 'player_count_unavailable' })
    } finally {
      setPlayerPresenceLoading(false)
    }
  })

  useEffect(() => {
    if (server.runtime.container_state !== 'running') return undefined

    loadPlayerPresence()

    const intervalId = window.setInterval(() => {
      loadPlayerPresence()
    }, 15000)

    return () => {
      window.clearInterval(intervalId)
    }
  }, [server.id, server.runtime.container_state])

  const loadWhitelist = useEffectEvent(async () => {
    if (!canManageWhitelist) {
      setWhitelistEntries([])
      setWhitelistEnabled(true)
      setWhitelistStagedOnly(false)
      setWhitelistError(null)
      return false
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
      const body = await readJsonResponse(response, 'ホワイトリスト状態の取得に失敗しました。時間をおいて再読込してください。')

      if (!response.ok) {
        throw new Error(body.error || 'ホワイトリストを取得できませんでした。')
      }

      setWhitelistEntries(body.whitelist.entries || [])
      setWhitelistEnabled(body.whitelist.enabled !== false)
      setWhitelistStagedOnly(body.whitelist.staged_only === true)
      return true
    } catch (error) {
      setWhitelistError(error.message)
      return false
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
    setRecentLogs({ available: false, lines: [], error_code: null })
    setRecentLogsError(null)
    setRconResult(null)
    setRconError(null)
    setSayMessage('')
    setKickPlayerName('')
    setKickReason('')
    setSelectedDifficulty(server.startup_settings.difficulty)
    setSelectedWeather('clear')
    setSelectedTime('day')
    setSelectedGamemode('survival')
    setGamemodePlayerName('')
  }, [server.id])

  useEffect(() => {
    loadWhitelist()
  }, [canManageWhitelist, server.id])

  const loadRecentLogs = useEffectEvent(async () => {
    setRecentLogsLoading(true)
    setRecentLogsError(null)

    try {
      const response = await fetch(`/servers/${server.id}/recent_logs.json`, {
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
        },
      })
      const body = await readJsonResponse(response, 'ログ取得の応答が不正です。')

      if (!response.ok) {
        throw new Error(body.error || 'ログを取得できませんでした。')
      }

      setRecentLogs(body.recent_logs)
    } catch (error) {
      setRecentLogs({ available: false, lines: [], error_code: 'logs_unavailable' })
      setRecentLogsError(error.message)
    } finally {
      setRecentLogsLoading(false)
    }
  })

  useEffect(() => {
    loadRecentLogs()
  }, [server.id])

  async function executeRconCommand(payload, { onSuccess } = {}) {
    setRconLoading(true)
    setRconError(null)
    setRconResult(null)

    try {
      const response = await fetch(`/servers/${server.id}/rcon_command.json`, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify(payload),
      })
      const body = await readJsonResponse(response, 'RCON コマンドの応答が不正です。')

      if (!response.ok) {
        throw new Error(body.error || 'RCON コマンドを実行できませんでした。')
      }

      setRconResult(body)
      onSuccess?.()
    } catch (error) {
      setRconError(error.message)
    } finally {
      setRconLoading(false)
    }
  }

  async function mutateWhitelist(url, { method = 'POST', body } = {}) {
    setWhitelistMutationLoading(true)
    setWhitelistError(null)
    let fallbackError = null

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
      const payload = await readJsonResponse(response, 'ホワイトリスト操作の応答が不正です。状態を再確認します。')

      if (!response.ok) {
        throw new Error(payload.error || 'ホワイトリスト操作に失敗しました。')
      }
    } catch (error) {
      fallbackError = error
    } finally {
      const refreshed = await loadWhitelist()
      if (!refreshed && fallbackError) {
        setWhitelistError(fallbackError.message)
      }
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
          <Grid.Col span={12}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <Stack gap="md">
                <Group justify="space-between" align="center">
                  <Text fw={700}>プレイヤー</Text>
                  {playerPresenceLoading ? <Loader size="sm" /> : null}
                </Group>
                <Divider />
                {playerPresence?.available ? (
                  <Stack gap="xs">
                    <Text fw={700} size="lg">{playerCountLabel(playerPresence)}</Text>
                    <Text c="dimmed" size="sm">
                      {playerPresence.online_players?.length > 0
                        ? playerPresence.online_players.join(', ')
                        : '現在オンラインのプレイヤーはいません。'}
                    </Text>
                  </Stack>
                ) : (
                  <Text c="dimmed">
                    {server.runtime.container_state === 'running' ? '取得できません。' : '停止中です。'}
                  </Text>
                )}
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={12}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <Stack gap="md">
                <Group justify="space-between" align="center">
                  <Text fw={700}>最近のログ</Text>
                  <Group gap="xs">
                    {recentLogsLoading ? <Loader size="sm" /> : null}
                    <Button
                      leftSection={<IconRefresh size={14} />}
                      onClick={() => loadRecentLogs()}
                      size="xs"
                      type="button"
                      variant="default"
                    >
                      再読込
                    </Button>
                  </Group>
                </Group>
                <Divider />
                {recentLogsError ? (
                  <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="ログを取得できませんでした" variant="light">
                    {recentLogsError}
                  </Alert>
                ) : null}
                {recentLogs?.available ? (
                  <ScrollArea.Autosize mah={280} offsetScrollbars>
                    <Code block style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                      {recentLogs.lines.join('\n')}
                    </Code>
                  </ScrollArea.Autosize>
                ) : (
                  <Text c="dimmed" size="sm">
                    取得できません。
                  </Text>
                )}
              </Stack>
            </Paper>
          </Grid.Col>

          <Grid.Col span={12}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <Stack gap="md">
                <Text fw={700}>初期設定</Text>
                <Divider />
                <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
                  <DetailLine label="難易度" value={startupValueLabel('difficulty', server.startup_settings.difficulty)} />
                  <DetailLine label="ゲームモード" value={startupValueLabel('gamemode', server.startup_settings.gamemode)} />
                  <DetailLine label="最大プレイヤー数" value={server.startup_settings.max_players} />
                  <DetailLine label="PvP" value={startupValueLabel('pvp', server.startup_settings.pvp)} />
                  <DetailLine label="ハードコア" value={startupValueLabel('hardcore', server.startup_settings.hardcore)} />
                  <DetailLine label="MOTD" value={server.startup_settings.motd ? server.startup_settings.motd : '-'} />
                </SimpleGrid>
              </Stack>
            </Paper>
          </Grid.Col>

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

        {canRunRconCommand ? (
          <Paper p="lg" radius="lg" shadow="sm" withBorder>
            <Stack gap="md">
              <Group justify="space-between" align="center">
                <Text fw={700}>サーバー操作</Text>
                {rconLoading ? <Loader size="sm" /> : null}
              </Group>
              <Divider />
              <SimpleGrid cols={{ base: 1, md: 2 }} spacing="md">
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>難易度</Text>
                    <Group align="flex-end" grow>
                      <Select data={DIFFICULTY_OPTIONS} onChange={(value) => setSelectedDifficulty(value || 'easy')} value={selectedDifficulty} />
                      <Button onClick={() => executeRconCommand({ command_key: 'difficulty', args: { difficulty: selectedDifficulty } })} type="button">
                        変更
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>天気</Text>
                    <Group align="flex-end" grow>
                      <Select data={WEATHER_OPTIONS} onChange={(value) => setSelectedWeather(value || 'clear')} value={selectedWeather} />
                      <Button onClick={() => executeRconCommand({ command_key: 'weather', args: { weather: selectedWeather } })} type="button">
                        変更
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>時刻</Text>
                    <Group align="flex-end" grow>
                      <Select data={TIME_OPTIONS} onChange={(value) => setSelectedTime(value || 'day')} value={selectedTime} />
                      <Button onClick={() => executeRconCommand({ command_key: 'time_set', args: { time: selectedTime } })} type="button">
                        変更
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>保存</Text>
                    <Button onClick={() => executeRconCommand({ command_key: 'save_all', args: {} })} type="button" variant="light">
                      save-all
                    </Button>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>ゲームモード</Text>
                    <Select
                      data={[
                        { value: 'survival', label: 'Survival' },
                        { value: 'creative', label: 'Creative' },
                        { value: 'adventure', label: 'Adventure' },
                        { value: 'spectator', label: 'Spectator' },
                      ]}
                      onChange={(value) => setSelectedGamemode(value || 'survival')}
                      value={selectedGamemode}
                    />
                    <TextInput
                      label="プレイヤー名"
                      onChange={(event) => setGamemodePlayerName(event.currentTarget.value)}
                      placeholder="未入力で全体"
                      value={gamemodePlayerName}
                    />
                    <Group justify="flex-end">
                      <Button
                        onClick={() => executeRconCommand({
                          command_key: 'gamemode',
                          args: {
                            gamemode: selectedGamemode,
                            player_name: gamemodePlayerName,
                          },
                        }, { onSuccess: () => setGamemodePlayerName('') })}
                        type="button"
                      >
                        変更
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>お知らせ</Text>
                    <Group align="flex-end" grow>
                      <TextInput
                        onChange={(event) => setSayMessage(event.currentTarget.value)}
                        placeholder="再起動を開始します"
                        value={sayMessage}
                      />
                      <Button
                        disabled={sayMessage.trim().length === 0}
                        onClick={() => executeRconCommand({ command_key: 'say', args: { message: sayMessage } }, { onSuccess: () => setSayMessage('') })}
                        type="button"
                      >
                        送信
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
                <Paper p="md" radius="lg" withBorder>
                  <Stack gap="sm">
                    <Text fw={700}>キック</Text>
                    <TextInput
                      label="プレイヤー名"
                      onChange={(event) => setKickPlayerName(event.currentTarget.value)}
                      placeholder="Steve"
                      value={kickPlayerName}
                    />
                    <TextInput
                      label="理由"
                      onChange={(event) => setKickReason(event.currentTarget.value)}
                      placeholder="メンテナンス中です"
                      value={kickReason}
                    />
                    <Group justify="flex-end">
                      <Button
                        color="red"
                        disabled={kickPlayerName.trim().length === 0}
                        onClick={() => executeRconCommand({
                          command_key: 'kick',
                          args: {
                            player_name: kickPlayerName,
                            reason: kickReason,
                          },
                        }, {
                          onSuccess: () => {
                            setKickPlayerName('')
                            setKickReason('')
                          },
                        })}
                        type="button"
                        variant="light"
                      >
                        実行
                      </Button>
                    </Group>
                  </Stack>
                </Paper>
              </SimpleGrid>
              {rconError ? (
                <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="操作を実行できませんでした" variant="light">
                  {rconError}
                </Alert>
              ) : null}
              {rconResult ? (
                <Alert color="teal" radius="lg" title="実行結果" variant="light">
                  <Stack gap={6}>
                    <Code block>{rconResult.command}</Code>
                    <Code block style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                      {rconResult.response_body || '応答は空です。'}
                    </Code>
                  </Stack>
                </Alert>
              ) : null}
            </Stack>
          </Paper>
        ) : null}

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
                    停止中のため、変更は保存のみ行います。
                  </Alert>
                ) : null}

                {!whitelistEnabled ? (
                  <Alert color="yellow" radius="lg" title="現在は無効です" variant="light">
                    登録済みプレイヤーでも接続制限はかかりません。
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
                    <Text c="dimmed" size="sm">登録済みプレイヤー</Text>
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
                            style={{
                              cursor: whitelistMutationLoading ? 'default' : 'pointer',
                              fontFamily: 'ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace',
                              fontSize: '0.85rem',
                              letterSpacing: '0.04em',
                              textTransform: 'none',
                            }}
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
