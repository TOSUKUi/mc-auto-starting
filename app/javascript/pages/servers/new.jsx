import {
  Button,
  Code,
  Divider,
  Grid,
  Group,
  List,
  NumberInput,
  Paper,
  Select,
  SimpleGrid,
  Stack,
  Text,
  TextInput,
  Title,
  ThemeIcon,
} from '@mantine/core'
import { Head, Link, useForm } from '@inertiajs/react'
import { IconCircleCheck, IconPlugConnected, IconServer2, IconSparkles } from '@tabler/icons-react'

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

export default function ServersNew({ form_defaults, provider_name, public_endpoint, template_options }) {
  const form = useForm(form_defaults)
  const normalizedHostname = normalizeHostname(form.data.hostname)
  const preview = endpointPreview(form.data.hostname, public_endpoint)
  const hasTouchedHostname = form.data.hostname.trim().length > 0
  const resourceHints = [
    { label: 'Memory', value: `${form.data.memory_mb.toLocaleString()} MB` },
    { label: 'Disk', value: `${form.data.disk_mb.toLocaleString()} MB` },
    { label: 'Template', value: template_options.find((item) => item.value === form.data.template_kind)?.label ?? 'Paper' },
  ]

  const submit = (event) => {
    event?.preventDefault()
    form.transform((data) => ({ minecraft_server: data }))
    form.post('/servers')
  }

  return (
    <>
      <Head title="New Server" />

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
                    Server creation
                  </Text>
                </Group>
                <Title order={1}>New server</Title>
                <Text c="dimmed" maw={760}>
                  Submit the create request here, preview the public endpoint before commit, and hand provisioning off to the
                  background worker.
                </Text>
              </Stack>

              <Button
                href="/servers"
                renderRoot={(props) => <Link {...props} href="/servers" />}
                variant="light"
                w={{ base: '100%', sm: 'auto' }}
              >
                Back to servers
              </Button>
            </Group>

            <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    Preview target
                  </Text>
                  <Text fw={800} size="lg">
                    hostname:port
                  </Text>
                  <Text c="dimmed" size="sm">
                    Users will connect through the shared public edge, not a direct backend port.
                  </Text>
                </Stack>
              </Paper>
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    Create status
                  </Text>
                  <Text fw={800} size="lg">
                    Queue-backed intake
                  </Text>
                  <Text c="dimmed" size="sm">
                    The provisional record is stored immediately, then provisioning continues asynchronously.
                  </Text>
                </Stack>
              </Paper>
              <Paper p="md" radius="lg" withBorder>
                <Stack gap={4}>
                  <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                    Current baseline
                  </Text>
                  <Text fw={800} size="lg">
                    {provider_name}
                  </Text>
                  <Text c="dimmed" size="sm">
                    The provider client is configured centrally, so this page stays aligned with the active backend.
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
                  <Stack gap={4}>
                    <Title order={3}>Request details</Title>
                    <Text c="dimmed" size="sm">
                      Fill in the operator-facing metadata first. Valid requests are accepted now and move into provisioning.
                    </Text>
                  </Stack>

                  <TextInput
                    error={form.errors.name}
                    label="Server name"
                    onChange={(event) => form.setData('name', event.currentTarget.value)}
                    placeholder="Main Survival"
                    required
                    value={form.data.name}
                  />
                  <TextInput
                    description={
                      hasTouchedHostname
                        ? `Normalized preview: ${normalizedHostname || 'empty'}`
                        : 'Lowercase letters, numbers, and internal hyphens only.'
                    }
                    error={form.errors.hostname}
                    label="Hostname prefix"
                    onChange={(event) => form.setData('hostname', event.currentTarget.value)}
                    placeholder="main-survival"
                    required
                    value={form.data.hostname}
                  />
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <TextInput
                        error={form.errors.minecraft_version}
                        label="Minecraft version"
                        onChange={(event) => form.setData('minecraft_version', event.currentTarget.value)}
                        required
                        value={form.data.minecraft_version}
                      />
                    </Grid.Col>
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <Select
                        data={template_options}
                        error={form.errors.template_kind}
                        label="Template"
                        onChange={(value) => form.setData('template_kind', value ?? form_defaults.template_kind)}
                        required
                        value={form.data.template_kind}
                      />
                    </Grid.Col>
                  </Grid>
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <NumberInput
                        allowDecimal={false}
                        error={form.errors.memory_mb}
                        label="Memory (MB)"
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
                        error={form.errors.disk_mb}
                        label="Disk (MB)"
                        min={1024}
                        onChange={(value) => form.setData('disk_mb', value || 0)}
                        required
                        thousandSeparator=","
                        value={form.data.disk_mb}
                      />
                    </Grid.Col>
                  </Grid>

                  <Divider label="Draft summary" labelPosition="center" />
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
                      Submit create request
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
                    <Title order={3}>Endpoint preview</Title>
                  </Group>
                  <Text c="dimmed" size="sm">
                    This is the only public target users should ever see. Backend coordinates stay hidden behind mc-router.
                  </Text>
                  <Paper p="md" radius="lg" style={{ background: 'rgba(25, 135, 84, 0.08)' }} withBorder>
                    <Stack gap={3}>
                      <Text c="dimmed" fw={700} size="xs" tt="uppercase">
                        Connection target
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
                      Public port <Code>{public_endpoint.public_port}</Code>
                    </Text>
                    <Text size="sm">
                      Domain <Code>{public_endpoint.public_domain}</Code>
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
                    <Title order={4}>Current scope</Title>
                  </Group>
                  <Text c="dimmed" size="sm">
                    The create intake is live now. Provider orchestration and route apply still continue behind the background
                    worker boundary.
                  </Text>
                  <List spacing="xs" size="sm" icon={<IconCircleCheck size={14} />}>
                    <List.Item>Accepted requests persist a provisional server record immediately.</List.Item>
                    <List.Item>Preview always uses the shared public endpoint.</List.Item>
                    <List.Item>The detail page becomes the source of truth for `provisioning` progress.</List.Item>
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
