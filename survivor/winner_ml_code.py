import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
# Load the data
file_path = "C:\R\portfolio\data_model.csv"
data = pd.read_csv(file_path)

# Display the first few rows of the data to understand its structure
data.head()

# Drop the index column
data_cleaned = data.drop(columns=['Unnamed: 0'])
data_cleaned.head()
# Define features and target variable
X = data_cleaned.drop(columns=['winner'])
y = data_cleaned['winner']
y.head()
# Identify categorical and numerical features
categorical_features = ['state', 'gender', 'cleaned_race_eth', 'occupation', 'personality_type']
numerical_features = ['Picks', 'age']

# Create a preprocessing pipeline
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numerical_features),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)
    ]
)

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Apply preprocessing to the training and testing data
X_train_processed = preprocessor.fit_transform(X_train)
X_test_processed = preprocessor.transform(X_test)

X_train_processed.shape, X_test_processed.shape

