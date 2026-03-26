import { Alert, Button, Code, Divider, Grid, Group, NumberInput, Paper, Select, SimpleGrid, Stack, Text, TextInput, Title, ThemeIcon } from '@mantine/core'
import { Head, Link, useForm } from '@inertiajs/react'
import { IconInfoCircle, IconPlugConnected, IconSparkles } from '@tabler/icons-react'

function normalizeHostname(value) {
  return value.trim().toLowerCase()
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
          style={{
            background:
              'linear-gradient(135deg, rgba(14,116,144,0.08) 0%, rgba(255,255,255,0.7) 44%, rgba(226,244,233,0.95) 100%)',
          }}
          withBorder
        >
          <Stack gap="lg">
            <Group align="flex-start" justify="space-between" wrap="wrap">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                    <IconSparkles size={18} />
                  </ThemeIcon>
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">New Server</Text>
                </Group>
                <Title order={1}>新しいサーバーを作成</Title>
                <Text c="dimmed" maw={640}>
                  プレイヤーに見せる名前と接続先を決めれば作成できます。技術的な設定はアプリ側で自動的に整えます。
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
                    description="一覧や詳細画面に出る名前です。あとで見てわかる名前にしてください。"
                    label="サーバー名"
                    onChange={(event) => form.setData('name', event.currentTarget.value)}
                    placeholder="みんなのサバイバル"
                    required
                    value={form.data.name}
                  />
                  <TextInput
                    description={
                      hasTouchedHostname
                        ? `使用されるホスト名: ${normalizedHostname || 'empty'}`
                        : '半角英小文字・数字・ハイフンだけ使えます。'
                    }
                    error={form.errors.hostname}
                    label="アドレス名"
                    onChange={(event) => form.setData('hostname', event.currentTarget.value)}
                    placeholder="main-survival"
                    required
                    value={form.data.hostname}
                  />
                  <Select
                    data={minecraft_version_options}
                    description="使う Paper イメージのタグを選びます。"
                    error={form.errors.minecraft_version}
                    label="Minecraft バージョン"
                    onChange={(value) => form.setData('minecraft_version', value || '')}
                    required
                    value={form.data.minecraft_version}
                  />
                  <Divider label="起動設定" labelPosition="center" />
                  <Text c="dimmed" size="sm">
                    初期作成で調整できるのはメモリだけです。細かい内部設定は自動で管理されます。
                  </Text>
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12 }}>
                      <NumberInput
                        allowDecimal={false}
                        error={form.errors.memory_mb}
                        label="メモリ (MB)"
                        min={512}
                        onChange={(value) => form.setData('memory_mb', value || 0)}
                        required
                        thousandSeparator=","
                        value={form.data.memory_mb}
                      />
                    </Grid.Col>
                  </Grid>
                  <Alert color="blue" icon={<IconInfoCircle size={16} />} radius="md" variant="light">
                    作成後すぐに共有できるよう、公開アドレスまでまとめて準備します。
                  </Alert>

                  <Divider label="作成内容の確認" labelPosition="center" />
                  <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="sm">
                    {resourceHints.map((item) => (
                      <Paper key={item.label} p="md" radius="lg" withBorder>
                        <Stack gap={2}>
                          <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                            {item.label}
                          </Text>
                          <Text fw={800} size="lg">
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
                      variant="gradient"
                      gradient={{ from: 'blue', to: 'cyan' }}
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
                    Minecraft のサーバーアドレスに入力する内容
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

              <Paper p="lg" radius="lg" shadow="sm" withBorder>
                <Stack gap="sm">
                  <Alert color="blue" icon={<IconInfoCircle size={16} />} radius="md" variant="light">
                    内部の実行環境は自動で管理されます。ここではプレイヤー向けの名前と接続先だけ気にすれば十分です。
                  </Alert>
                </Stack>
              </Paper>
            </Stack>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
