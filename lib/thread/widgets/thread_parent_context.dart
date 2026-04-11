import 'package:flutter/material.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/thread/utils/thread_formatters.dart';

/// Renders the ancestor chain ABOVE the focused note (X/Twitter style).
/// Oldest ancestor is first; the last item connects via thread line to the
/// root note card below.
class ThreadParentContext extends StatelessWidget {
  const ThreadParentContext({
    super.key,
    required this.notes,
    required this.profiles,
    required this.onNoteTap,
  });

  final List<NoteEntity> notes;
  final Map<String, ProfileEntity> profiles;
  final void Function(String noteId) onNoteTap;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(notes.length, (i) {
        return _ParentNoteRow(
          note: notes[i],
          profile: profiles[notes[i].authorPubkey],
          onTap: () => onNoteTap(notes[i].id),
        );
      }),
    );
  }
}

class _ParentNoteRow extends StatelessWidget {
  const _ParentNoteRow({
    required this.note,
    required this.profile,
    required this.onTap,
  });

  final NoteEntity note;
  final ProfileEntity? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.name ??
        profile?.username ??
        threadShortPubkey(note.authorPubkey);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + thread line column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  UserAvatar(
                    seed: note.authorPubkey,
                    photoUrl: profile?.avatarUrl,
                    size: 38,
                    borderRadius: 19,
                  ),
                  // Thread line always shown — connects down to next item
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Content — muted, no action buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name · time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${threadTimeAgo(note.created)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Content — muted, capped to avoid overshadowing root note
                    Text(
                      note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
