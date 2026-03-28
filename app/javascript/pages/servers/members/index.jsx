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
  ThemeIcon,
  Title,
} from '@mantine/core'
import { Head, Link, router, useForm } from '@inertiajs/react'
import { IconSparkles, IconUsers } from '@tabler/icons-react'

function labelize(value) {
  if (value === 'manager') return '運用担当'
  if (value === 'viewer') return '閲覧のみ'
  return value
}

function formatTimestamp(value) {
  return new Intl.DateTimeFormat('ja-JP', {
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
      <Head title={`${server.name} のメンバー`} />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{ background: '#26231e', borderColor: '#4a4338' }}
          withBorder
        >
          <Stack gap="lg">
            <Text href={`/servers/${server.id}`} renderRoot={(props) => <Link {...props} href={`/servers/${server.id}`} />} size="sm">
              サーバー詳細へ戻る
            </Text>
            <Group justify="space-between" align="flex-start" wrap="wrap">
              <Stack gap={6}>
                <Group gap="xs">
                  <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                    <IconSparkles size={18} />
                  </ThemeIcon>
                  <Text c="stone.5" fw={700} size="sm" tt="uppercase">
                    メンバー
                  </Text>
                </Group>
                <Title order={1}>メンバー管理</Title>
                <Text c="stone.3">{server.name}</Text>
                <Code>{server.connection_target}</Code>
              </Stack>
              <Paper p="md" radius="lg" withBorder style={{ background: '#23211d', borderColor: '#4a4338', minWidth: 220 }}>
                <Stack gap={4}>
                  <Text c="stone.5" fw={700} size="xs" tt="uppercase">
                    オーナー
                  </Text>
                  <Code>{server.owner_display_name}</Code>
                  <Text c="stone.4" size="xs">
                    {server.owner_discord_user_id}
                  </Text>
                </Stack>
              </Paper>
            </Group>
          </Stack>
        </Paper>

        <Paper p="lg" radius="lg" withBorder>
          <Stack gap="md">
            <Group gap="xs">
              <ThemeIcon color="blue" radius="xl" size={30} variant="light">
                <IconUsers size={16} />
              </ThemeIcon>
              <Title order={3}>追加</Title>
            </Group>
            <form onSubmit={submit}>
              <Stack gap="md">
                <Group align="flex-end" grow>
                  <TextInput
                    error={form.errors.user || form.errors.discord_user_id}
                    label="Discord ユーザー ID"
                    onChange={(event) => form.setData('discord_user_id', event.currentTarget.value)}
                    placeholder="123456789012345678"
                    value={form.data.discord_user_id}
                  />
                  <Select
                    data={roleOptions}
                    error={form.errors.role}
                    label="権限"
                    onChange={(value) => form.setData('role', value ?? form_defaults.role)}
                    value={form.data.role}
                  />
                  <Button loading={form.processing} type="submit">
                    追加
                  </Button>
                </Group>
              </Stack>
            </form>
          </Stack>
        </Paper>

        <Paper p="lg" radius="lg" withBorder>
          <Stack gap="md">
            <Group justify="space-between">
              <Title order={3}>現在のメンバー</Title>
              <Badge color="blue" variant="light">
                {memberships.length} 件
              </Badge>
            </Group>

            {memberships.length === 0 ? (
              <Text c="dimmed">まだメンバーは追加されていません。</Text>
            ) : (
              <Table highlightOnHover horizontalSpacing="md" verticalSpacing="sm">
                <Table.Thead>
                  <Table.Tr>
                    <Table.Th>Discord</Table.Th>
                    <Table.Th>権限</Table.Th>
                    <Table.Th>追加日時</Table.Th>
                    <Table.Th>操作</Table.Th>
                  </Table.Tr>
                </Table.Thead>
                <Table.Tbody>
                  {memberships.map((membership) => (
                    <Table.Tr key={membership.id}>
                      <Table.Td>
                        <Stack gap={2}>
                          <Code>{membership.display_name}</Code>
                          <Text c="dimmed" size="xs">
                            {membership.discord_user_id}
                          </Text>
                        </Stack>
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
                          削除
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
