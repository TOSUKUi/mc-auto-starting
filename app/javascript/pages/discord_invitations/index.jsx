import {
  Alert,
  Badge,
  Button,
  CopyButton,
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
import { Head, useForm } from '@inertiajs/react'
import { IconCheck, IconCopy, IconLink, IconUserPlus } from '@tabler/icons-react'

const STATUS_COLORS = {
  active: 'teal',
  used: 'blue',
  expired: 'gray',
  revoked: 'red',
}

function formatTimestamp(value) {
  if (!value) return '-'

  return new Intl.DateTimeFormat('ja-JP', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function labelizeStatus(value) {
  switch (value) {
    case 'active':
      return '有効'
    case 'used':
      return '使用済み'
    case 'expired':
      return '期限切れ'
    case 'revoked':
      return '無効'
    default:
      return value
  }
}

export default function DiscordInvitationsIndex({ expiration_options, form_defaults, invitations, pending_invite_url }) {
  const form = useForm(form_defaults)

  const submit = (event) => {
    event?.preventDefault()
    form.transform((data) => ({ discord_invitation: data }))
    form.post('/discord-invitations')
  }

  return (
    <>
      <Head title="招待" />

      <Stack gap="xl">
        <Paper
          p="xl"
          radius="xl"
          shadow="sm"
          style={{ background: '#26231e', borderColor: '#4a4338' }}
          withBorder
        >
          <Stack gap="md">
            <Group gap="xs">
              <ThemeIcon color="teal" radius="xl" size={36} variant="light">
                <IconUserPlus size={18} />
              </ThemeIcon>
              <Text c="stone.5" fw={700} size="sm" tt="uppercase">
                Invite
              </Text>
            </Group>
            <Title order={1}>Discord 招待リンク</Title>
            <Text c="stone.3" maw={720}>
              参加を許可する Discord ユーザーを指定して、手動で 1 回使い切りの招待リンクを発行します。
            </Text>
          </Stack>
        </Paper>

        {pending_invite_url ? (
          <Alert color="teal" icon={<IconLink size={16} />} radius="md" variant="light">
            <Stack gap="sm">
              <Text fw={700}>発行した招待リンク</Text>
              <Text style={{ overflowWrap: 'anywhere', wordBreak: 'break-word' }}>{pending_invite_url}</Text>
              <Text c="dimmed" size="sm">
                raw token は保存しないため、この URL を後から同じ形で再表示することはできません。
              </Text>
              <Group justify="flex-start">
                <CopyButton value={pending_invite_url}>
                  {({ copied, copy }) => (
                    <Button
                      color={copied ? 'teal' : 'gray'}
                      leftSection={copied ? <IconCheck size={16} /> : <IconCopy size={16} />}
                      onClick={copy}
                      size="xs"
                      type="button"
                      variant="light"
                    >
                      {copied ? 'コピー済み' : 'リンクをコピー'}
                    </Button>
                  )}
                </CopyButton>
              </Group>
            </Stack>
          </Alert>
        ) : null}

        <Paper p="lg" radius="lg" shadow="sm" withBorder>
          <form onSubmit={submit}>
            <Stack gap="md">
              <Title order={3}>新しい招待を発行</Title>

              <TextInput
                description="招待したい相手の Discord user ID をそのまま入力します。"
                error={form.errors.discord_user_id}
                label="Discord user ID"
                onChange={(event) => form.setData('discord_user_id', event.currentTarget.value)}
                placeholder="123456789012345678"
                required
                value={form.data.discord_user_id}
              />

              <Select
                data={expiration_options}
                error={form.errors.expires_at}
                label="有効期限"
                onChange={(value) => form.setData('expires_in_days', value ?? form_defaults.expires_in_days)}
                required
                value={form.data.expires_in_days}
              />

              <TextInput
                description="用途のメモが必要なときだけ使います。"
                error={form.errors.note}
                label="メモ"
                onChange={(event) => form.setData('note', event.currentTarget.value)}
                placeholder="mod チーム用"
                value={form.data.note}
              />

              <Group justify="flex-end">
                <Button loading={form.processing} type="submit">
                  招待リンクを発行
                </Button>
              </Group>
              <Text c="dimmed" size="sm">
                発行後はその場でリンクをコピーしてください。あとから確認できるのは発行履歴と状態だけです。
              </Text>
            </Stack>
          </form>
        </Paper>

        <Paper p="lg" radius="lg" shadow="sm" withBorder>
          <Stack gap="md">
            <Group justify="space-between">
              <Title order={3}>発行済みの招待</Title>
              <Text c="dimmed" size="sm">
                {invitations.length} 件
              </Text>
            </Group>

            {invitations.length === 0 ? (
              <Text c="dimmed">まだ招待はありません。</Text>
            ) : (
              <Table highlightOnHover striped>
                <Table.Thead>
                  <Table.Tr>
                    <Table.Th>Discord user ID</Table.Th>
                    <Table.Th>状態</Table.Th>
                    <Table.Th>期限</Table.Th>
                    <Table.Th>メモ</Table.Th>
                    <Table.Th />
                  </Table.Tr>
                </Table.Thead>
                <Table.Tbody>
                  {invitations.map((invitation) => (
                    <Table.Tr key={invitation.id}>
                      <Table.Td>
                        <Stack gap={2}>
                          <Text fw={700}>{invitation.discord_user_id}</Text>
                          <Text c="dimmed" size="xs">
                            発行 {formatTimestamp(invitation.created_at)}
                          </Text>
                        </Stack>
                      </Table.Td>
                      <Table.Td>
                        <Badge color={STATUS_COLORS[invitation.status] ?? 'gray'} variant="light">
                          {labelizeStatus(invitation.status)}
                        </Badge>
                      </Table.Td>
                      <Table.Td>{formatTimestamp(invitation.expires_at)}</Table.Td>
                      <Table.Td>{invitation.note || '-'}</Table.Td>
                      <Table.Td>
                        {invitation.status === 'active' ? (
                          <Button
                            color="red"
                            onClick={() => form.patch(`/discord-invitations/${invitation.id}/revoke`, { preserveScroll: true })}
                            size="xs"
                            type="button"
                            variant="light"
                          >
                            無効化
                          </Button>
                        ) : (
                          <Text c="dimmed" size="sm">
                            {invitation.status === 'used' ? '使用済み' : '終了'}
                          </Text>
                        )}
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
