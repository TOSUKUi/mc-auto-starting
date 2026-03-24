import {
  Alert,
  Button,
  Code,
  Grid,
  Group,
  NumberInput,
  Paper,
  Select,
  Stack,
  Text,
  TextInput,
  Title,
} from '@mantine/core'
import { Head, Link, useForm } from '@inertiajs/react'
import { IconPlugConnected, IconRouteAltLeft } from '@tabler/icons-react'

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

export default function ServersNew({ blocker_message, form_defaults, public_endpoint, template_options }) {
  const form = useForm(form_defaults)
  const preview = endpointPreview(form.data.hostname, public_endpoint)

  const submit = (event) => {
    event.preventDefault()
    form.post('/servers')
  }

  return (
    <>
      <Head title="New Server" />

      <Stack gap="xl">
        <Stack gap={4}>
          <Text component={Link} href="/servers" size="sm">
            Back to servers
          </Text>
          <Title order={1}>New server</Title>
          <Text c="dimmed" maw={720}>
            Prepare the requested hostname, template, and resource sizing first. The actual create request is still blocked
            until the external execution-provider contract is confirmed.
          </Text>
        </Stack>

        {blocker_message ? (
          <Alert color="orange" icon={<IconRouteAltLeft size={16} />} radius="md" variant="light">
            {blocker_message}
          </Alert>
        ) : null}

        <Grid gutter="lg">
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Paper p="lg" radius="lg" withBorder>
              <form onSubmit={submit}>
                <Stack gap="md">
                  <TextInput
                    label="Server name"
                    onChange={(event) => form.setData('name', event.currentTarget.value)}
                    placeholder="Main Survival"
                    required
                    value={form.data.name}
                  />
                  <TextInput
                    description="Lowercase letters, numbers, and internal hyphens only."
                    label="Hostname prefix"
                    onChange={(event) => form.setData('hostname', event.currentTarget.value)}
                    placeholder="main-survival"
                    required
                    value={form.data.hostname}
                  />
                  <Grid gutter="md">
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <TextInput
                        label="Minecraft version"
                        onChange={(event) => form.setData('minecraft_version', event.currentTarget.value)}
                        required
                        value={form.data.minecraft_version}
                      />
                    </Grid.Col>
                    <Grid.Col span={{ base: 12, sm: 6 }}>
                      <Select
                        data={template_options}
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
                        label="Disk (MB)"
                        min={1024}
                        onChange={(value) => form.setData('disk_mb', value || 0)}
                        required
                        thousandSeparator=","
                        value={form.data.disk_mb}
                      />
                    </Grid.Col>
                  </Grid>

                  <Group justify="flex-end">
                    <Button loading={form.processing} type="submit">
                      Submit create request
                    </Button>
                  </Group>
                </Stack>
              </form>
            </Paper>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 4 }}>
            <Stack gap="lg">
              <Paper p="lg" radius="lg" withBorder>
                <Stack gap="sm">
                  <Group gap="xs">
                    <IconPlugConnected size={18} />
                    <Title order={3}>Endpoint preview</Title>
                  </Group>
                  <Text c="dimmed" size="sm">
                    Users will always connect with the public shared endpoint.
                  </Text>
                  <Text size="sm">
                    Public port <Code>{public_endpoint.public_port}</Code>
                  </Text>
                  <Text size="sm">
                    Domain <Code>{public_endpoint.public_domain}</Code>
                  </Text>
                  <Text size="sm">
                    FQDN <Code>{preview?.fqdn ?? 'hostname.mc.tosukui.xyz'}</Code>
                  </Text>
                  <Text size="sm">
                    Target <Code>{preview?.connectionTarget ?? 'hostname.mc.tosukui.xyz:42434'}</Code>
                  </Text>
                </Stack>
              </Paper>

              <Paper p="lg" radius="lg" withBorder>
                <Stack gap="sm">
                  <Title order={4}>Current scope</Title>
                  <Text c="dimmed" size="sm">
                    This screen is in place first so the request shape, preview data, and operator flow can stabilize before
                    provider orchestration lands.
                  </Text>
                </Stack>
              </Paper>
            </Stack>
          </Grid.Col>
        </Grid>
      </Stack>
    </>
  )
}
