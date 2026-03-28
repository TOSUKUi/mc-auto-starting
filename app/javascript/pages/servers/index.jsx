import {
  Badge,
  Button,
  Card,
  Group,
  Paper,
  SimpleGrid,
  Stack,
  Text,
  TextInput,
  ThemeIcon,
  Title,
} from '@mantine/core'
import { Head, Link } from '@inertiajs/react'
import { IconAlertTriangle, IconSearch, IconServer2, IconSparkles } from '@tabler/icons-react'
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

function playerCountLabel(playerPresence) {
  if (!playerPresence?.available) return null
  if (playerPresence.max_players == null) return `${playerPresence.online_count}人`

  return `${playerPresence.online_count} / ${playerPresence.max_players}人`
}

function needsAttention(server) {
  return server.status !== 'ready' || server.route.last_apply_status === 'failed'
}

function StatCard({ label, value, tone = 'gray' }) {
  return (
    <Card padding="lg" radius="xl" withBorder>
      <Stack gap={4}>
        <Text c="dimmed" fw={600} size="xs" tt="uppercase">
          {label}
        </Text>
        <Text fw={800} size="2rem">
          {value}
        </Text>
        <Text c={`${tone}.6`} size="sm">
          現在の表示
        </Text>
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
          server.owner_display_name,
          server.access_role,
          server.status,
        ].some((value) => value?.toLowerCase().includes(normalizedQuery)),
      )
    : servers

  return (
    <>
      <Head title="サーバー一覧" />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{ background: '#26231e', borderColor: '#4a4338' }}
          withBorder
        >
          <Stack gap="lg">
            <Group align="flex-start" justify="space-between">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                    <IconSparkles size={18} />
                  </ThemeIcon>
                  <Text c="stone.5" fw={700} size="sm" tt="uppercase">一覧</Text>
                </Group>
                <Title order={1}>サーバー一覧</Title>
                <Text c="stone.3" maw={720} size="md">
                  自分のサーバーと共有中のサーバーを、接続先と状態中心で確認できます。
                </Text>
              </Stack>

              <Button
                href="/servers/new"
                renderRoot={(props) => <Link {...props} href="/servers/new" />}
                color="grass"
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
                プレイヤーには接続先だけ共有すれば十分です。
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
                        <Text fw={700} size="lg" style={{ maxWidth: '100%', overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                          {server.name}
                        </Text>
                        <Badge color="blue" variant="light">
                          {labelize(server.access_role)}
                        </Badge>
                        <Badge color="grape" variant="light">
                          種類 {runtimeFamilyLabel(server.runtime_family)}
                        </Badge>
                        <Badge color={STATUS_COLORS[server.status] ?? 'gray'} variant="light">
                          {labelize(server.status)}
                        </Badge>
                      </Group>
                      <Text c="dimmed" size="sm">
                        共有アドレス
                      </Text>
                      <Text fw={700} size="lg" style={{ maxWidth: '100%', overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                        {server.connection_target}
                      </Text>
                    </Stack>

                    {needsAttention(server) ? (
                      <Group gap="xs">
                        {server.route.last_apply_status === 'failed' ? (
                          <Badge color="red" leftSection={<IconAlertTriangle size={12} />} variant="light">
                            公開反映エラー
                          </Badge>
                        ) : null}
                        <Badge color="orange" leftSection={<IconAlertTriangle size={12} />} variant="light">
                          要確認
                        </Badge>
                      </Group>
                    ) : null}
                  </Group>

                  <Group justify="flex-end">
                    <Button
                      href={`/servers/${server.id}`}
                      renderRoot={(props) => <Link {...props} href={`/servers/${server.id}`} />}
                      size="xs"
                      variant="light"
                    >
                      詳細を見る
                    </Button>
                  </Group>

                  <SimpleGrid cols={{ base: 1, sm: 4 }} spacing="sm">
                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap={2}>
                        <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                          種類
                        </Text>
                        <Text fw={700}>{runtimeFamilyLabel(server.runtime_family)}</Text>
                      </Stack>
                    </Paper>
                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap={2}>
                        <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                          Minecraft バージョン
                        </Text>
                        <Text fw={700}>{server.minecraft_version_display}</Text>
                        {selectedVersionNote(server) ? (
                          <Text c="dimmed" size="sm">{selectedVersionNote(server)}</Text>
                        ) : null}
                      </Stack>
                    </Paper>
                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap={2}>
                        <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                          オーナー
                        </Text>
                        <Text fw={700} style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>{server.owner_display_name}</Text>
                      </Stack>
                    </Paper>
                    {server.player_presence?.available ? (
                      <Paper p="md" radius="lg" withBorder>
                        <Stack gap={2}>
                          <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                            プレイヤー
                          </Text>
                          <Text fw={700}>{playerCountLabel(server.player_presence)}</Text>
                        </Stack>
                      </Paper>
                    ) : null}
                  </SimpleGrid>
                </Stack>
              </Paper>
            ))}
          </Stack>
        )}
      </Stack>
    </>
  )
}
