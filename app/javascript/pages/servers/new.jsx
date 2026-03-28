import { Button, Code, Divider, Grid, Group, NumberInput, Paper, Select, SimpleGrid, Stack, Switch, Text, TextInput, Title, ThemeIcon } from '@mantine/core'
import { Head, Link, useForm } from '@inertiajs/react'
import { IconPlugConnected, IconSparkles } from '@tabler/icons-react'

const MIN_MEMORY_MB = 512
const MAX_MEMORY_MB = 4096

function normalizeHostname(value) {
  return value.trim().toLowerCase()
}

function sanitizeHostnameInput(value) {
  return value
    .toLowerCase()
    .replace(/\s+/g, '')
    .replace(/[^a-z0-9-]/g, '')
    .slice(0, 63)
}

function clampMemory(value) {
  if (!Number.isFinite(value)) return 0

  return Math.min(MAX_MEMORY_MB, Math.max(MIN_MEMORY_MB, value))
}

function endpointPreview(hostname, publicEndpoint) {
  const normalized = normalizeHostname(hostname)
  if (!normalized) return null

  return {
    fqdn: `${normalized}.${publicEndpoint.public_domain}`,
    connectionTarget: `${normalized}.${publicEndpoint.public_domain}:${publicEndpoint.public_port}`,
  }
}

function selectedRuntimeLabel(value, options) {
  return options.find((option) => option.value === value)?.label || value
}

function selectedVersionLabel(value, options) {
  return options.find((option) => option.value === value)?.label || value
}

function toSelectBoolean(value) {
  return value ? 'true' : 'false'
}

function runtimeFamilyDescription(value) {
  if (value === 'vanilla') return '公式が提供するサーバーで、最新バージョンへの対応がされています。'

  return '軽量化や拡張に向いた Paper 系サーバーです。'
}

export default function ServersNew({ create_quota, form_defaults, runtime_family_options, minecraft_version_options_by_runtime_family, public_endpoint, validation_errors = {} }) {
  const form = useForm(form_defaults)
  const normalizedHostname = normalizeHostname(form.data.hostname)
  const preview = endpointPreview(form.data.hostname, public_endpoint)
  const hasTouchedHostname = form.data.hostname.trim().length > 0
  const minecraftVersionOptions = minecraft_version_options_by_runtime_family[form.data.runtime_family] || []
  const resourceHints = [
    { label: 'サーバーソフト', value: selectedRuntimeLabel(form.data.runtime_family, runtime_family_options) },
    { label: 'バージョン', value: selectedVersionLabel(form.data.minecraft_version, minecraftVersionOptions) },
    { label: 'メモリ', value: `${form.data.memory_mb.toLocaleString()} MB` },
    { label: '接続先', value: preview?.connectionTarget ?? 'hostname.mc.tosukui.xyz:42434' },
  ]
  const projectedMemoryTotal = (create_quota?.used_mb || 0) + form.data.memory_mb
  const fieldError = (name) => form.errors[name] || validation_errors[name]

  const submit = (event) => {
    event?.preventDefault()
    form.transform((data) => ({ minecraft_server: data }))
    form.post('/servers')
  }

  return (
    <>
      <Head title="サーバー作成" />

      <Stack gap="xl">
        <Paper
          p={{ base: 'lg', sm: 'xl' }}
          radius="xl"
          shadow="sm"
          style={{ background: '#26231e', borderColor: '#4a4338' }}
          withBorder
        >
          <Stack gap="lg">
            <Group align="flex-start" justify="space-between" wrap="wrap">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                    <IconSparkles size={18} />
                  </ThemeIcon>
                  <Text c="stone.5" fw={700} size="sm" tt="uppercase">作成</Text>
                </Group>
                <Title order={1}>新しいサーバーを作成</Title>
                <Text c="stone.3" maw={640}>
                  サーバー名、ホスト名、バージョンを決めて作成します。
                </Text>
              </Stack>

              <Button
                href="/servers"
                renderRoot={(props) => <Link {...props} href="/servers" />}
                variant="light"
                w={{ base: '100%', sm: 'auto' }}
              >
                サーバー一覧へ戻る
              </Button>
            </Group>
          </Stack>
        </Paper>

        <Grid gutter="lg">
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <form onSubmit={submit}>
                <Stack gap="md">
                  <Title order={3}>基本情報</Title>

                  <TextInput
                    error={fieldError('name')}
                    description="一覧と詳細で表示する名前です。"
                    label="サーバー名"
                    onChange={(event) => form.setData('name', event.currentTarget.value)}
                    placeholder="みんなのサバイバル"
                    required
                    value={form.data.name}
                  />
                  <TextInput
                    description={
                      hasTouchedHostname
                        ? `使用するホスト名: ${normalizedHostname || '-'}`
                        : '半角英小文字・数字・ハイフンのみ使えます。'
                    }
                    error={fieldError('hostname')}
                    inputMode="url"
                    label="ホスト名"
                    maxLength={63}
                    onChange={(event) => form.setData('hostname', sanitizeHostnameInput(event.currentTarget.value))}
                    pattern="[a-z0-9-]+"
                    placeholder="main-survival"
                    required
                    value={form.data.hostname}
                  />
                  <Select
                    data={runtime_family_options}
                    description={runtimeFamilyDescription(form.data.runtime_family)}
                    error={fieldError('runtime_family')}
                    label="サーバーソフト"
                    onChange={(value) => {
                      const nextRuntimeFamily = value || ''
                      const nextVersionOptions = minecraft_version_options_by_runtime_family[nextRuntimeFamily] || []

                      form.setData({
                        ...form.data,
                        runtime_family: nextRuntimeFamily,
                        minecraft_version: nextVersionOptions[0]?.value || '',
                      })
                    }}
                    required
                    value={form.data.runtime_family}
                  />
                  <Select
                    data={minecraftVersionOptions}
                    description="起動する Minecraft バージョンです。"
                    error={fieldError('minecraft_version')}
                    label="Minecraft バージョン"
                    onChange={(value) => form.setData('minecraft_version', value || '')}
                    required
                    value={form.data.minecraft_version}
                  />
                  <Divider label="起動設定" labelPosition="center" />
                  <Stack gap="md">
                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap="sm">
                        <Stack gap={2}>
                          <Text fw={700}>リソースと参加条件</Text>
                          <Text c="dimmed" size="sm">
                            まずはメモリと参加人数を決めます。
                          </Text>
                        </Stack>
                        <Grid gutter="md">
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <NumberInput
                              allowDecimal={false}
                              error={fieldError('memory_mb')}
                              hideControls
                              label="メモリ (MB)"
                              max={MAX_MEMORY_MB}
                              min={MIN_MEMORY_MB}
                              onChange={(value) => form.setData('memory_mb', clampMemory(Number(value)))}
                              required
                              step={512}
                              thousandSeparator=","
                              value={form.data.memory_mb}
                            />
                          </Grid.Col>
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <NumberInput
                              allowDecimal={false}
                              error={fieldError('max_players')}
                              hideControls
                              label="最大プレイヤー数"
                              max={100}
                              min={1}
                              onChange={(value) => form.setData('max_players', Math.max(1, Math.min(100, Number(value) || 1)))}
                              required
                              value={form.data.max_players}
                            />
                          </Grid.Col>
                        </Grid>
                      </Stack>
                    </Paper>

                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap="sm">
                        <Stack gap={2}>
                          <Text fw={700}>ワールド設定</Text>
                          <Text c="dimmed" size="sm">
                            難易度やゲームモードなど、プレイ感に関わる設定です。
                          </Text>
                        </Stack>
                        <Grid gutter="md">
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <Select
                              data={[
                                { value: 'easy', label: 'Easy' },
                                { value: 'normal', label: 'Normal' },
                                { value: 'hard', label: 'Hard' },
                                { value: 'peaceful', label: 'Peaceful' },
                              ]}
                              description="モンスターや飢餓の強さを決めます。"
                              error={fieldError('difficulty')}
                              label="難易度"
                              onChange={(value) => form.setData('difficulty', value || '')}
                              required
                              value={form.data.difficulty}
                            />
                          </Grid.Col>
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <Select
                              data={[
                                { value: 'survival', label: 'Survival' },
                                { value: 'creative', label: 'Creative' },
                                { value: 'adventure', label: 'Adventure' },
                                { value: 'spectator', label: 'Spectator' },
                              ]}
                              description="新規参加時の標準ゲームモードです。"
                              error={fieldError('gamemode')}
                              label="ゲームモード"
                              onChange={(value) => form.setData('gamemode', value || '')}
                              required
                              value={form.data.gamemode}
                            />
                          </Grid.Col>
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <Select
                              data={[
                                { value: 'true', label: '有効' },
                                { value: 'false', label: '無効' },
                              ]}
                              description="プレイヤー同士の攻撃を許可するかどうかです。"
                              error={fieldError('pvp')}
                              label="PvP"
                              onChange={(value) => form.setData('pvp', value === 'true')}
                              required
                              value={toSelectBoolean(form.data.pvp)}
                            />
                          </Grid.Col>
                          <Grid.Col span={{ base: 12, sm: 6 }}>
                            <Switch
                              checked={!!form.data.hardcore}
                              description="有効にすると死亡時に観戦者モードになります。"
                              error={fieldError('hardcore')}
                              label="ハードコア"
                              onChange={(event) => {
                                const checked = event.currentTarget.checked
                                form.setData('hardcore', checked)
                              }}
                            />
                          </Grid.Col>
                        </Grid>
                      </Stack>
                    </Paper>

                    <Paper p="md" radius="lg" withBorder>
                      <Stack gap="sm">
                        <Stack gap={2}>
                          <Text fw={700}>サーバー表示</Text>
                          <Text c="dimmed" size="sm">
                            サーバー一覧などで見える紹介文です。
                          </Text>
                        </Stack>
                        <TextInput
                          description="空欄でも作成できます。"
                          error={fieldError('motd')}
                          label="MOTD"
                          onChange={(event) => form.setData('motd', event.currentTarget.value)}
                          placeholder="みんなのサバイバルへようこそ"
                          value={form.data.motd}
                        />
                      </Stack>
                    </Paper>
                  </Stack>

                  <Divider label="作成内容の確認" labelPosition="center" />
                  <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="sm">
                    {resourceHints.map((item) => (
                      <Paper key={item.label} p="md" radius="lg" withBorder>
                        <Stack gap={2}>
                          <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                            {item.label}
                          </Text>
                          <Text fw={800} size="lg" style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                            {item.value}
                          </Text>
                        </Stack>
                      </Paper>
                    ))}
                  </SimpleGrid>

                  <Group justify="flex-end">
                    <Button
                      fullWidth
                      loading={form.processing}
                      onClick={submit}
                      type="submit"
                      color="grass"
                    >
                      この内容でサーバーを作成
                    </Button>
                  </Group>
                </Stack>
              </form>
            </Paper>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 4 }}>
            <Stack gap="lg">
              <Paper p="lg" radius="lg" shadow="sm" withBorder>
                <Stack gap="md">
                  <Group gap="xs">
                    <ThemeIcon color="cyan" radius="xl" size={32} variant="light">
                      <IconPlugConnected size={16} />
                    </ThemeIcon>
                    <Title order={3}>接続先プレビュー</Title>
                  </Group>
                  <Text c="dimmed" size="sm">
                    Minecraft で入力する接続先
                  </Text>
                  <Paper p="md" radius="lg" style={{ background: 'rgba(25, 135, 84, 0.08)' }} withBorder>
                    <Stack gap={3}>
                      <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                        接続先
                      </Text>
                      <Text fw={900} size="xl" style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>
                        {preview?.connectionTarget ?? 'hostname.mc.tosukui.xyz:42434'}
                      </Text>
                    </Stack>
                  </Paper>
                  <Stack gap={6}>
                    <Text size="sm">
                      アドレス{' '}
                      <Code style={{ overflowWrap: 'anywhere', wordBreak: 'break-word', whiteSpace: 'normal' }}>
                        {preview?.fqdn ?? 'hostname.mc.tosukui.xyz'}
                      </Code>
                    </Text>
                    <Text size="sm">
                      公開ポート <Code>{public_endpoint.public_port}</Code>
                    </Text>
                    <Text size="sm">
                      ドメイン <Code>{public_endpoint.public_domain}</Code>
                    </Text>
                  </Stack>
                </Stack>
              </Paper>

              {create_quota?.applies ? (
                <Paper p="lg" radius="lg" shadow="sm" withBorder>
                  <Stack gap="md">
                    <Title order={3}>作成上限</Title>
                    <Text c="dimmed" size="sm">
                      運用者は所有サーバーの合計メモリを {create_quota.limit_mb.toLocaleString()} MB まで使えます。
                    </Text>
                    <Stack gap={6}>
                      <Text size="sm">
                        現在使用中 <Code>{create_quota.used_mb.toLocaleString()} MB</Code>
                      </Text>
                      <Text size="sm">
                        残り <Code>{(create_quota.remaining_mb || 0).toLocaleString()} MB</Code>
                      </Text>
                      <Text size="sm">
                        今回作成後の見込み <Code>{projectedMemoryTotal.toLocaleString()} MB</Code>
                      </Text>
                    </Stack>
                  </Stack>
                </Paper>
              ) : null}
            </Stack>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
