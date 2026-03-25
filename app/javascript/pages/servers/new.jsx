import {
  Alert,
  Button,
  Code,
  Divider,
  Grid,
  Group,
  List,
  NumberInput,
  Paper,
  SimpleGrid,
  Stack,
  Text,
  TextInput,
  Title,
  ThemeIcon,
} from '@mantine/core'
import { Head, Link, useForm } from '@inertiajs/react'
import { IconAlertCircle, IconCircleCheck, IconPlugConnected, IconServer2, IconSparkles } from '@tabler/icons-react'

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

export default function ServersNew({ form_defaults, provider_name, public_endpoint, template_available, template_kind }) {
  const form = useForm(form_defaults)
  const normalizedHostname = normalizeHostname(form.data.hostname)
  const preview = endpointPreview(form.data.hostname, public_endpoint)
  const hasTouchedHostname = form.data.hostname.trim().length > 0
  const resourceHints = [
    { label: 'メモリ', value: `${form.data.memory_mb.toLocaleString()} MB` },
    { label: 'ディスク', value: `${form.data.disk_mb.toLocaleString()} MB` },
    { label: 'サーバー方式', value: '標準' },
  ]

  const submit = (event) => {
    event?.preventDefault()
    if (!template_available) return
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
              'linear-gradient(135deg, rgba(13,110,253,0.10) 0%, rgba(25,135,84,0.08) 42%, rgba(248,249,250,0.95) 100%)',
          }}
          withBorder
        >
          <Stack gap="lg">
            <Group align="flex-start" justify="space-between" wrap="wrap">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="cyan" radius="xl" size={36} variant="light">
                    <IconServer2 size={18} />
                  </ThemeIcon>
                  <Text c="dimmed" fw={700} size="sm" tt="uppercase">
                    Create Server
                  </Text>
                </Group>
                <Title order={1}>新しいサーバーを作成</Title>
                <Text c="dimmed" maw={760}>
                  名前とアドレス、遊びたいバージョンを入れれば、そのまま作成できます。細かい設定は下で変えられますが、
                  ふつうは初期値のままで大丈夫です。
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

            <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    接続先
                  </Text>
                  <Text fw={800} size="lg">
                    hostname:port
                  </Text>
                  <Text c="dimmed" size="sm">
                    プレイヤーにはこのアドレスだけを案内します。裏側の接続先は見せません。
                  </Text>
                </Stack>
              </Paper>
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    作成方法
                  </Text>
                  <Text fw={800} size="lg">
                    受付後に自動作成
                  </Text>
                  <Text c="dimmed" size="sm">
                    先に受付だけ保存して、そのあと裏でプロビジョニングを進めます。
                  </Text>
                </Stack>
              </Paper>
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    実行基盤
                  </Text>
                  <Text fw={800} size="lg">
                    {provider_name}
                  </Text>
                  <Text c="dimmed" size="sm">
                    どの実行基盤に作るかは管理側で固定しています。この画面では迷わせません。
                  </Text>
                </Stack>
              </Paper>
            </SimpleGrid>
          </Stack>
        </Paper>

        <Grid gutter="lg">
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Paper p="lg" radius="lg" shadow="sm" withBorder>
              <form onSubmit={submit}>
                <Stack gap="md">
                  {!template_available ? (
                    <Alert color="red" icon={<IconAlertCircle size={18} />} radius="lg" title="作成設定が未接続です" variant="light">
                      実行基盤側に、いまの標準サーバー作成設定がまだ入っていません。管理側で `paper` の provisioning
                      template を設定するまで、この画面からは作成できません。
                    </Alert>
                  ) : null}

                  <Stack gap={4}>
                    <Title order={3}>基本情報</Title>
                    <Text c="dimmed" size="sm">
                      まずはこれだけ入れてください。受け付けたら、そのまま作成処理に進みます。
                    </Text>
                  </Stack>

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
                        ? `使用されるアドレス名: ${normalizedHostname || 'empty'}`
                        : '半角英小文字・数字・ハイフンだけ使えます。'
                    }
                    error={form.errors.hostname}
                    label="アドレス名"
                    onChange={(event) => form.setData('hostname', event.currentTarget.value)}
                    placeholder="main-survival"
                    required
                    value={form.data.hostname}
                  />
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12 }}>
                      <TextInput
                        description="迷ったら、遊ぶ予定のクライアントと同じバージョンを入れてください。"
                        error={form.errors.minecraft_version}
                        label="Minecraft バージョン"
                        onChange={(event) => form.setData('minecraft_version', event.currentTarget.value)}
                        placeholder="1.21.4"
                        required
                        value={form.data.minecraft_version}
                      />
                    </Grid.Col>
                  </Grid>
                  <Paper p="md" radius="lg" style={{ background: 'rgba(13, 110, 253, 0.06)' }} withBorder>
                    <Stack gap={4}>
                      <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                        サーバー方式
                      </Text>
                      <Text fw={800} size="lg">
                        標準構成
                      </Text>
                      <Text c="dimmed" size="sm">
                        プラグイン互換を重視した標準構成で作成します。内部的には `{template_kind}` テンプレートを使いますが、
                        利用者がここを選ぶ必要はありません。
                      </Text>
                    </Stack>
                  </Paper>
                  <Divider label="詳細設定（通常はそのままでOK）" labelPosition="center" />
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <NumberInput
                        allowDecimal={false}
                        description="重くなってきたら後で増やす前提で、まずは初期値で十分です。"
                        error={form.errors.memory_mb}
                        label="メモリ (MB)"
                        min={512}
                        onChange={(value) => form.setData('memory_mb', value || 0)}
                        required
                        thousandSeparator=","
                        value={form.data.memory_mb}
                      />
                    </Grid.Col>
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <NumberInput
                        allowDecimal={false}
                        description="ワールドやプラグインが増えてきたら後で見直します。"
                        error={form.errors.disk_mb}
                        label="ディスク (MB)"
                        min={1024}
                        onChange={(value) => form.setData('disk_mb', value || 0)}
                        required
                        thousandSeparator=","
                        value={form.data.disk_mb}
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
                          <Text fw={800} size="lg">
                            {item.value}
                          </Text>
                        </Stack>
                      </Paper>
                    ))}
                  </SimpleGrid>

                  <Group justify="flex-end">
                    <Button
                      disabled={!template_available}
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
                    プレイヤーに伝えるのはこの接続先だけです。サーバーの裏側の接続情報は隠したままにします。
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
                      FQDN{' '}
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
                  <Group gap="xs">
                    <ThemeIcon color="teal" radius="xl" size={32} variant="light">
                      <IconSparkles size={16} />
                    </ThemeIcon>
                    <Title order={4}>この画面でやること</Title>
                  </Group>
                  <Text c="dimmed" size="sm">
                    ここでは「作成受付」までを行います。実際のサーバー作成、ルーティング反映、状態更新は裏で続きます。
                  </Text>
                  <List spacing="xs" size="sm" icon={<IconCircleCheck size={14} />}>
                    <List.Item>受け付けた時点で、仮のサーバーレコードを先に保存します。</List.Item>
                    <List.Item>接続先は常に共通の公開エンドポイントで案内します。</List.Item>
                    <List.Item>サーバー方式は標準構成に固定して、選択で迷わせません。</List.Item>
                    <List.Item>作成の進み具合は詳細画面で確認します。</List.Item>
                  </List>
                </Stack>
              </Paper>
            </Stack>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
