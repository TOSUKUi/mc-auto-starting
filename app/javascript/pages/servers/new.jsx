import { Button, Code, Divider, Grid, Group, NumberInput, Paper, Select, SimpleGrid, Stack, Text, TextInput, Title, ThemeIcon } from '@mantine/core'
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

export default function ServersNew({ form_defaults, minecraft_version_options, public_endpoint }) {
  const form = useForm(form_defaults)
  const normalizedHostname = normalizeHostname(form.data.hostname)
  const preview = endpointPreview(form.data.hostname, public_endpoint)
  const hasTouchedHostname = form.data.hostname.trim().length > 0
  const resourceHints = [
    { label: 'バージョン', value: form.data.minecraft_version },
    { label: 'メモリ', value: `${form.data.memory_mb.toLocaleString()} MB` },
    { label: '接続先', value: preview?.connectionTarget ?? 'hostname.mc.tosukui.xyz:42434' },
  ]

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
                  <Text c="stone.5" fw={700} size="sm" tt="uppercase">New Server</Text>
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
                    error={form.errors.name}
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
                    error={form.errors.hostname}
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
                    data={minecraft_version_options}
                    description="起動する Minecraft バージョンです。"
                    error={form.errors.minecraft_version}
                    label="Minecraft バージョン"
                    onChange={(value) => form.setData('minecraft_version', value || '')}
                    required
                    value={form.data.minecraft_version}
                  />
                  <Divider label="起動設定" labelPosition="center" />
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12 }}>
                      <NumberInput
                        allowDecimal={false}
                        error={form.errors.memory_mb}
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
                  </Grid>

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
            </Stack>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
