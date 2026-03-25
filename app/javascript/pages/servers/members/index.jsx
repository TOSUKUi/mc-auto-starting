import {
  Badge,
  Button,
  Code,
  Group,
  Paper,
  Select,
  Stack,
  Table,
  Text,
  TextInput,
  Title,
} from '@mantine/core'
import { Head, Link, router, useForm } from '@inertiajs/react'

function labelize(value) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function formatTimestamp(value) {
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export default function ServerMembersIndex({ available_roles, form_defaults, memberships, server }) {
  const form = useForm(form_defaults)

  const roleOptions = available_roles.map((role) => ({
    value: role,
    label: labelize(role),
  }))

  const submit = (event) => {
    event.preventDefault()
    form.post(`/servers/${server.id}/members`)
  }

  return (
    <>
      <Head title={`${server.name} Members`} />

      <Stack gap="xl">
        <Stack gap={4}>
          <Text href={`/servers/${server.id}`} renderRoot={(props) => <Link {...props} href={`/servers/${server.id}`} />} size="sm">
            Back to server
          </Text>
          <Group justify="space-between">
            <Stack gap={0}>
              <Title order={1}>Members</Title>
              <Text c="dimmed">{server.name}</Text>
            </Stack>
            <Stack align="flex-end" gap={2}>
              <Text c="dimmed" size="sm">
                Owner
              </Text>
              <Code>{server.owner_email_address}</Code>
            </Stack>
          </Group>
          <Text c="dimmed">
            Public target <Code>{server.connection_target}</Code>
          </Text>
        </Stack>

        <Paper p="lg" radius="lg" withBorder>
          <form onSubmit={submit}>
            <Stack gap="md">
              <Group align="flex-end" grow>
                <TextInput
                  error={form.errors.user || form.errors.email_address}
                  label="User email"
                  onChange={(event) => form.setData('email_address', event.currentTarget.value)}
                  placeholder="member@example.com"
                  value={form.data.email_address}
                />
                <Select
                  data={roleOptions}
                  error={form.errors.role}
                  label="Role"
                  onChange={(value) => form.setData('role', value ?? form_defaults.role)}
                  value={form.data.role}
                />
                <Button loading={form.processing} type="submit">
                  Add member
                </Button>
              </Group>
            </Stack>
          </form>
        </Paper>

        <Paper p="lg" radius="lg" withBorder>
          <Stack gap="md">
            <Group justify="space-between">
              <Title order={3}>Current memberships</Title>
              <Badge color="blue" variant="light">
                {memberships.length} entries
              </Badge>
            </Group>

            {memberships.length === 0 ? (
              <Text c="dimmed">No members have been added yet.</Text>
            ) : (
              <Table highlightOnHover horizontalSpacing="md" verticalSpacing="sm">
                <Table.Thead>
                  <Table.Tr>
                    <Table.Th>Email</Table.Th>
                    <Table.Th>Role</Table.Th>
                    <Table.Th>Added</Table.Th>
                    <Table.Th>Actions</Table.Th>
                  </Table.Tr>
                </Table.Thead>
                <Table.Tbody>
                  {memberships.map((membership) => (
                    <Table.Tr key={membership.id}>
                      <Table.Td>
                        <Code>{membership.email_address}</Code>
                      </Table.Td>
                      <Table.Td>
                        <Select
                          data={roleOptions}
                          onChange={(value) => {
                            if (!value || value === membership.role) return

                            router.patch(
                              `/servers/${server.id}/members/${membership.id}`,
                              { server_member: { role: value } },
                              { preserveScroll: true },
                            )
                          }}
                          value={membership.role}
                          w={160}
                        />
                      </Table.Td>
                      <Table.Td>{formatTimestamp(membership.created_at)}</Table.Td>
                      <Table.Td>
                        <Button
                          color="red"
                          onClick={() =>
                            router.delete(`/servers/${server.id}/members/${membership.id}`, { preserveScroll: true })
                          }
                          size="xs"
                          variant="light"
                        >
                          Remove
                        </Button>
                      </Table.Td>
                    </Table.Tr>
                  ))}
                </Table.Tbody>
              </Table>
            )}
          </Stack>
        </Paper>
      </Stack>
    </>
  )
}
