# Assessment Management Guide

## Production Setup

### Architecture
- **Admin Panel**: Streamlit-based admin panel for managing assessment questions
- **Database**: Firebase Firestore (`intellitrain` database)
- **Flutter App**: Reads assessments in real-time from Firestore

### Managing Questions

#### Via Admin Panel (Recommended)
1. Run your Streamlit admin panel
2. Add, edit, or delete assessments and questions
3. Changes are reflected in the app instantly

#### Via Firebase Console (Quick edits)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select: IntelliTrain project
3. Navigate to: Firestore Database > intellitrain > assessments
4. Click on any assessment document
5. Edit the `questions` array directly
6. Changes are live immediately!

### Adding New Questions via Firebase Console

In the `questions` array, add a new object with this structure:

```json
{
  "id": "unique_id",
  "text": "Your question here?",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctOptionIndex": 0,
  "concept": "Topic Name",
  "difficulty": "Easy",
  "section": "Section Name"
}
```

### Important Notes
- End users can only view and take assessments
- Only admins can manage questions via the admin panel or Firebase Console
- All changes in Firebase are reflected in the app instantly
- The Flutter app uses `AssessmentService` to stream data from Firestore
